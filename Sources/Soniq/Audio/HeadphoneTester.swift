import AVFoundation
import Combine

/// Plays calibration sounds straight to the current output to check headphones and speakers.
final class HeadphoneTester: ObservableObject {
    enum Test: String, CaseIterable, Identifiable {
        case left, both, right, sweep, frequency, bass, phase
        var id: String { rawValue }

        var duration: Double {
            switch self {
            case .left, .right, .both: return 1.9
            case .sweep: return 6
            case .frequency: return 12
            case .bass: return 7
            case .phase: return 6
            }
        }
    }

    @Published private(set) var running: Test?
    @Published private(set) var progress: Double = 0
    /// Current sweep frequency in Hz (frequency and bass tests).
    @Published private(set) var frequency: Double = 0
    /// Current pan position, -1 … 1 (stereo sweep).
    @Published private(set) var pan: Double = 0
    /// True during the out-of-phase half of the phase test.
    @Published private(set) var inverted = false

    private var engine: AVAudioEngine?
    private var timer: Timer?
    private var startDate = Date()
    private let generator = Generator()

    func toggle(_ test: Test) {
        if running == test { stop() } else { play(test) }
    }

    func play(_ test: Test) {
        stop()
        let engine = AVAudioEngine()
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        guard sampleRate > 0, let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }

        generator.reset(test: test, sampleRate: sampleRate)
        let generator = self.generator
        let source = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let left = buffers[0].mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            let right = buffers.count > 1 ? buffers[1].mData?.assumingMemoryBound(to: Float.self) : nil
            generator.render(left: left, right: right, frames: Int(frameCount))
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            NSLog("Soniq: test tone failed: \(error)")
            return
        }

        self.engine = engine
        running = test
        startDate = Date()
        progress = 0
        let timer = Timer(timeInterval: 1 / 30, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        engine?.stop()
        engine = nil
        running = nil
        progress = 0
        inverted = false
        pan = 0
    }

    private func tick() {
        guard let test = running else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        guard elapsed < test.duration else { return stop() }
        let t = elapsed / test.duration
        progress = t
        switch test {
        case .frequency: frequency = Generator.sweep(t, from: 20, to: 20000)
        case .bass: frequency = Generator.sweep(t, from: 25, to: 160)
        case .sweep: pan = sin(t * 2 * .pi * 1.5)
        case .phase: inverted = t >= 0.5
        default: break
        }
    }
}

/// Realtime tone generator. Only touched by the audio thread after `reset`.
private final class Generator {
    private var test: HeadphoneTester.Test = .both
    private var sampleRate: Double = 48000
    private var sample = 0
    private var phase: Double = 0
    private var phase2: Double = 0
    private var noise: UInt32 = 0x1234_5678
    private var pink: (Float, Float, Float) = (0, 0, 0)

    func reset(test: HeadphoneTester.Test, sampleRate: Double) {
        self.test = test
        self.sampleRate = sampleRate
        sample = 0
        phase = 0
        phase2 = 0
        pink = (0, 0, 0)
    }

    static func sweep(_ t: Double, from low: Double, to high: Double) -> Double {
        low * pow(high / low, t)
    }

    func render(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>?, frames: Int) {
        let total = Double(test.duration) * sampleRate
        for i in 0..<frames {
            let t = Double(sample) / sampleRate
            let progress = min(Double(sample) / total, 1)
            var l: Float = 0
            var r: Float = 0

            switch test {
            case .left, .right, .both:
                // Three soft chimes.
                let pulse = t.truncatingRemainder(dividingBy: 0.6)
                let envelope = pulse < 0.45 ? Float(exp(-pulse * 7)) * Float(min(pulse * 200, 1)) : 0
                let tone = Float(sin(2 * .pi * 660 * t) + 0.45 * sin(2 * .pi * 990 * t)) * envelope * 0.3
                l = test == .right ? 0 : tone
                r = test == .left ? 0 : tone
            case .sweep:
                let position = sin(progress * 2 * .pi * 1.5)
                let angle = (position + 1) * .pi / 4
                let tone = Float(sin(2 * .pi * 440 * t) * 0.6 + sin(2 * .pi * 880 * t) * 0.25) * 0.3
                l = tone * Float(cos(angle))
                r = tone * Float(sin(angle))
            case .frequency, .bass:
                let (low, high, level): (Double, Double, Float) = test == .bass ? (25, 160, 0.45) : (20, 20000, 0.18)
                let f = Self.sweep(progress, from: low, to: high)
                phase += 2 * .pi * f / sampleRate
                if phase > 2 * .pi { phase -= 2 * .pi }
                l = Float(sin(phase)) * level
                r = l
            case .phase:
                let n = nextPink() * 0.25
                l = n
                r = progress < 0.5 ? n : -n
            }

            // 20 ms fade in/out to avoid clicks.
            let fade = Float(min(t / 0.02, (total / sampleRate - t) / 0.02, 1))
            left[i] = l * max(fade, 0)
            right?[i] = r * max(fade, 0)
            sample += 1
        }
    }

    private func nextPink() -> Float {
        noise ^= noise << 13
        noise ^= noise >> 17
        noise ^= noise << 5
        let white = Float(Int32(bitPattern: noise)) / Float(Int32.max)
        pink.0 = 0.997 * pink.0 + white * 0.029
        pink.1 = 0.985 * pink.1 + white * 0.032
        pink.2 = 0.950 * pink.2 + white * 0.048
        return (pink.0 + pink.1 + pink.2 + white * 0.1) * 2
    }
}
