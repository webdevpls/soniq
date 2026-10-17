import AudioToolbox
import CoreAudio
import Foundation

/// Per-app audio processing built on Core Audio process taps (macOS 14.2+).
///
/// The tap captures the app's audio and mutes its original output. A private
/// aggregate device (default output + tap) plays the captured audio back through
/// our gain, balance and effects. Destroying the tap instantly restores the original.
final class AppTap {
    static let aggregateUIDPrefix = "io.github.soniq.aggregate."

    enum TapError: Error, CustomStringConvertible {
        case status(String, OSStatus)
        var description: String {
            if case let .status(step, code) = self { return "\(step) failed (OSStatus \(code))" }
            return "unknown"
        }
    }

    /// Shared with the realtime IO thread. Float reads/writes are atomic on Apple silicon and x86_64.
    private final class RenderState {
        var target: Float
        var current: Float
        var balance: Float = 0
        var peak: Float = 0
        let effects = EffectsProcessor()
        var limiter = Limiter()
        init(_ gain: Float) { target = gain; current = gain }
    }

    let processObjects: Set<AudioObjectID>
    let outputUID: String

    private let state: RenderState
    private var settings: DSPSettings
    private var tapID = AudioObjectID.unknown
    private var aggregateID = AudioObjectID.unknown
    private var ioProcID: AudioDeviceIOProcID?
    private let queue = DispatchQueue(label: "io.github.soniq.io", qos: .userInteractive)

    /// Linear gain, up to 2× for boost.
    var gain: Float {
        get { state.target }
        set { state.target = max(0, min(newValue, 2)) }
    }

    /// -1 (left) … 1 (right).
    var balance: Float {
        get { state.balance }
        set { state.balance = max(-1, min(newValue, 1)) }
    }

    /// Peak input level since the last read, for diagnostics.
    func takePeak() -> Float {
        defer { state.peak = 0 }
        return state.peak
    }

    init(processObjects: [AudioObjectID], outputUID: String, gain: Float, balance: Float, settings: DSPSettings) {
        self.processObjects = Set(processObjects)
        self.outputUID = outputUID
        self.state = RenderState(gain)
        self.settings = settings
        self.balance = balance
    }

    deinit { invalidate() }

    func setEffects(_ settings: DSPSettings) {
        self.settings = settings
        state.effects.update(settings)
    }

    func start() throws {
        let description = CATapDescription(stereoMixdownOfProcesses: Array(processObjects))
        description.uuid = UUID()
        description.name = "Soniq"
        description.isPrivate = true
        description.muteBehavior = .mutedWhenTapped

        var tap = AudioObjectID.unknown
        var status = AudioHardwareCreateProcessTap(description, &tap)
        guard status == noErr else { throw TapError.status("Create process tap", status) }
        tapID = tap

        let aggregate: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Soniq",
            kAudioAggregateDeviceUIDKey: Self.aggregateUIDPrefix + UUID().uuidString,
            kAudioAggregateDeviceMainSubDeviceKey: outputUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceIsStackedKey: false,
            kAudioAggregateDeviceTapAutoStartKey: true,
            kAudioAggregateDeviceSubDeviceListKey: [[kAudioSubDeviceUIDKey: outputUID]],
            kAudioAggregateDeviceTapListKey: [[
                kAudioSubTapDriftCompensationKey: true,
                kAudioSubTapUIDKey: description.uuid.uuidString,
            ]],
        ]

        var device = AudioObjectID.unknown
        status = AudioHardwareCreateAggregateDevice(aggregate as CFDictionary, &device)
        guard status == noErr else { throw TapError.status("Create aggregate device", status) }
        aggregateID = device

        state.effects.prepare(sampleRate: device.get(kAudioDevicePropertyNominalSampleRate, as: Float64.self) ?? 48000)
        state.effects.update(settings)

        let state = self.state
        status = AudioDeviceCreateIOProcIDWithBlock(&ioProcID, device, queue) { _, input, _, output, _ in
            AppTap.render(input: input, output: output, state: state)
        }
        guard status == noErr else { throw TapError.status("Create IO proc", status) }

        status = AudioDeviceStart(device, ioProcID)
        guard status == noErr else { throw TapError.status("Start device", status) }
    }

    func invalidate() {
        if aggregateID != .unknown {
            if let ioProcID {
                AudioDeviceStop(aggregateID, ioProcID)
                AudioDeviceDestroyIOProcID(aggregateID, ioProcID)
                self.ioProcID = nil
            }
            AudioHardwareDestroyAggregateDevice(aggregateID)
            aggregateID = .unknown
        }
        if tapID != .unknown {
            AudioHardwareDestroyProcessTap(tapID)
            tapID = .unknown
        }
    }

    // MARK: Realtime render

    /// Reads the tap's stereo stream (the last input buffer), runs gain → balance → effects →
    /// limiter, and writes L/R to the first two output channels. Gain is ramped per buffer.
    private static func render(input: UnsafePointer<AudioBufferList>, output: UnsafeMutablePointer<AudioBufferList>, state: RenderState) {
        let inputs = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
        let outputs = UnsafeMutableAudioBufferListPointer(output)

        guard let tap = inputs.last, let tapData = tap.mData else {
            for buffer in outputs { if let data = buffer.mData { memset(data, 0, Int(buffer.mDataByteSize)) } }
            return
        }

        let target = state.target
        let start = state.current
        let effects = state.effects
        let effectsOn = effects.active
        let balance = state.balance
        let balanceL = balance > 0 ? 1 - balance : 1
        let balanceR = balance < 0 ? 1 + balance : 1

        let inChannels = max(Int(tap.mNumberChannels), 1)
        let frames = Int(tap.mDataByteSize) / (MemoryLayout<Float>.size * inChannels)
        let src = tapData.assumingMemoryBound(to: Float.self)
        let monoOut = outputs.count == 1 && outputs[0].mNumberChannels == 1
        let step = frames > 0 ? (target - start) / Float(frames) : 0
        var peak = state.peak
        var g = start

        for frame in 0..<frames {
            g += step
            let i = frame * inChannels
            var left = src[i]
            var right = inChannels > 1 ? src[i + 1] : left
            peak = max(peak, abs(left))

            left *= g * balanceL
            right *= g * balanceR
            if effectsOn { effects.process(&left, &right) }
            state.limiter.process(&left, &right)

            var channel = 0
            for buffer in outputs {
                guard let data = buffer.mData else { continue }
                let outChannels = max(Int(buffer.mNumberChannels), 1)
                let outFrames = Int(buffer.mDataByteSize) / (MemoryLayout<Float>.size * outChannels)
                if frame < outFrames {
                    let dst = data.assumingMemoryBound(to: Float.self) + frame * outChannels
                    for c in 0..<outChannels {
                        switch channel + c {
                        case 0: dst[c] = monoOut ? (left + right) * 0.5 : left
                        case 1: dst[c] = right
                        default: dst[c] = 0
                        }
                    }
                }
                channel += outChannels
            }
        }

        for buffer in outputs {
            guard let data = buffer.mData else { continue }
            let outChannels = max(Int(buffer.mNumberChannels), 1)
            let outFrames = Int(buffer.mDataByteSize) / (MemoryLayout<Float>.size * outChannels)
            if frames < outFrames {
                memset(data.assumingMemoryBound(to: Float.self) + frames * outChannels, 0,
                       (outFrames - frames) * outChannels * MemoryLayout<Float>.size)
            }
        }
        state.current = target
        state.peak = peak
    }
}
