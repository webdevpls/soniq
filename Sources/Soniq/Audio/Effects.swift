import Foundation

/// A sound "scene" preset. Every value describes the effect at full intensity.
struct SoundEffect: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    var eq: [Float] = DSPSettings.flatEQ
    var highpass: Double = 0
    var lowpass: Double = 0
    var width: Float = 1
    var reverb: Float = 0
    var room: Float = 0.5
    var damping: Float = 0.5
    var drive: Float = 0
    var compress: Float = 0
    var gain: Float = 0

    static let off = SoundEffect(id: "off", name: "Off", symbol: "circle.slash")

    static let all: [SoundEffect] = [
        off,
        SoundEffect(id: "bass", name: "Bass Boost", symbol: "speaker.wave.3.fill",
                    eq: [9, 8, 6, 3, 1, 0, 0, 0, 0, 0], compress: 0.3),
        SoundEffect(id: "party", name: "Party", symbol: "party.popper.fill",
                    eq: [6, 5, 3, 0, -1, 0, 2, 4, 5, 4], width: 1.45, reverb: 0.1, room: 0.45, compress: 0.45, gain: 1),
        SoundEffect(id: "underwater", name: "Underwater", symbol: "fish.fill",
                    eq: [4, 3, 1, 0, 0, 0, 0, 0, 0, 0], lowpass: 380, width: 0.6, reverb: 0.35, room: 0.65, damping: 0.8, gain: 2),
        SoundEffect(id: "concert", name: "Concert", symbol: "building.columns.fill",
                    eq: [2, 2, 1, 0, 0, 0, 1, 2, 2, 1], width: 1.3, reverb: 0.4, room: 0.88, damping: 0.35),
        SoundEffect(id: "nextRoom", name: "Next Room", symbol: "door.left.hand.closed",
                    eq: [3, 2, 0, 0, 0, 0, 0, 0, 0, 0], lowpass: 800, width: 0.7, reverb: 0.3, room: 0.4, damping: 0.7, gain: -3),
        SoundEffect(id: "car", name: "In the Car", symbol: "car.fill",
                    eq: [6, 6, 4, 1, 0, -1, 0, 1, 0, -2], lowpass: 11000, width: 0.85, reverb: 0.07, room: 0.15, damping: 0.6),
        SoundEffect(id: "radio", name: "Radio", symbol: "radio.fill",
                    eq: [0, 0, 0, 0, 2, 5, 4, 0, 0, 0], highpass: 380, lowpass: 3600, width: 0, drive: 0.45, compress: 0.5),
        SoundEffect(id: "wide", name: "3D Wide", symbol: "dot.radiowaves.left.and.right",
                    eq: [1, 1, 0, 0, 0, 0, 0, 1, 2, 2], width: 1.9, reverb: 0.06, room: 0.3),
        SoundEffect(id: "vocal", name: "Vocal", symbol: "person.wave.2.fill",
                    eq: [-4, -3, -1, 0, 2, 4, 5, 4, 2, 0], highpass: 90, compress: 0.35),
        SoundEffect(id: "night", name: "Night", symbol: "moon.stars.fill",
                    eq: [-3, -2, -1, 0, 0, 1, 1, 0, -1, -2], compress: 0.95, gain: 4),
        SoundEffect(id: "cinema", name: "Cinema", symbol: "film.fill",
                    eq: [6, 5, 2, 0, 0, 1, 2, 3, 3, 2], width: 1.5, reverb: 0.13, room: 0.7, compress: 0.3),
    ]
}

/// Concrete parameters handed to the realtime processor.
struct DSPSettings: Equatable {
    static let frequencies: [Double] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    static let flatEQ = [Float](repeating: 0, count: 10)

    var eq = flatEQ
    var highpass: Double = 0
    var lowpass: Double = 0
    var width: Float = 1
    var reverb: Float = 0
    var room: Float = 0.5
    var damping: Float = 0.5
    var drive: Float = 0
    var compress: Float = 0
    var gain: Float = 0

    static let neutral = DSPSettings()

    var isNeutral: Bool {
        eq.allSatisfy { abs($0) < 0.05 } && highpass == 0 && lowpass == 0 && abs(width - 1) < 0.01
            && reverb < 0.005 && drive < 0.005 && compress < 0.005 && abs(gain) < 0.05
    }

    /// Blends an effect by intensity and layers the user's bass/treble tweaks on top.
    static func make(effect: SoundEffect, intensity: Float, bass: Float, treble: Float) -> DSPSettings {
        let k = max(0, min(intensity, 1))
        var s = DSPSettings()
        s.eq = effect.eq.map { $0 * k }
        for (band, weight) in [(0, 1.0), (1, 0.85), (2, 0.45)] as [(Int, Float)] { s.eq[band] += bass * weight }
        for (band, weight) in [(7, 0.45), (8, 0.85), (9, 1.0)] as [(Int, Float)] { s.eq[band] += treble * weight }
        if effect.highpass > 0 { s.highpass = exp(log(20) + (log(effect.highpass) - log(20)) * Double(k)) }
        if effect.lowpass > 0 { s.lowpass = exp(log(20000) + (log(effect.lowpass) - log(20000)) * Double(k)) }
        s.width = 1 + (effect.width - 1) * k
        s.reverb = effect.reverb * k
        s.room = effect.room
        s.damping = effect.damping
        s.drive = effect.drive * k
        s.compress = effect.compress * k
        s.gain = effect.gain * k
        return s
    }
}

// MARK: - Realtime processor

/// Stereo effects chain: EQ → high/low-pass → drive → width → reverb → compressor.
/// Filter coefficients are double-buffered so the UI can change them while audio runs.
final class EffectsProcessor {
    private static let filterCount = 12 // 10 EQ bands + high-pass + low-pass
    private static let stride = 5

    private let coefficients: UnsafeMutablePointer<Float>
    private let history: UnsafeMutablePointer<Float>
    private var bank = 0
    private var reverb: Reverb?
    private(set) var sampleRate: Double = 48000

    private(set) var active = false
    private var width: Float = 1
    private var wet: Float = 0
    private var driveAmount: Float = 0
    private var driveNorm: Float = 1
    private var ratio: Float = 1
    private var makeup: Float = 1
    private var output: Float = 1
    private var envelope: Float = 0
    private var attack: Float = 0
    private var release: Float = 0

    init() {
        let count = 2 * Self.filterCount * Self.stride
        coefficients = .allocate(capacity: count)
        coefficients.initialize(repeating: 0, count: count)
        history = .allocate(capacity: Self.filterCount * 4)
        history.initialize(repeating: 0, count: Self.filterCount * 4)
    }

    deinit {
        coefficients.deallocate()
        history.deallocate()
    }

    /// Call before audio starts.
    func prepare(sampleRate: Double) {
        self.sampleRate = sampleRate
        reverb = Reverb(sampleRate: sampleRate)
        attack = Float(exp(-1 / (0.005 * sampleRate)))
        release = Float(exp(-1 / (0.15 * sampleRate)))
    }

    func update(_ s: DSPSettings) {
        guard !s.isNeutral else { active = false; return }
        let next = 1 - bank
        let base = coefficients + next * Self.filterCount * Self.stride
        for (i, frequency) in DSPSettings.frequencies.enumerated() {
            setPeaking(base + i * Self.stride, frequency: frequency, gain: Double(s.eq[i]))
        }
        setPass(base + 10 * Self.stride, frequency: s.highpass, highpass: true)
        setPass(base + 11 * Self.stride, frequency: s.lowpass, highpass: false)
        bank = next

        let peak = max(s.eq.max() ?? 0, 0)
        output = pow(10, (s.gain - peak * 0.5) / 20)
        width = s.width
        wet = s.reverb
        reverb?.configure(room: s.room, damping: s.damping)
        driveAmount = s.drive
        driveNorm = s.drive > 0 ? 1 / tanh(1 + s.drive * 4) : 1
        ratio = 1 + s.compress * 5
        makeup = pow(10, s.compress * 7 / 20)
        active = true
    }

    @inline(__always)
    func process(_ left: inout Float, _ right: inout Float) {
        let c = coefficients + bank * Self.filterCount * Self.stride
        var l = left * output
        var r = right * output

        for f in 0..<Self.filterCount {
            let k = c + f * Self.stride
            if k[0] == 1 && k[1] == 0 && k[2] == 0 { continue } // unity filter
            let zl = history + f * 4
            let yl = k[0] * l + zl[0]
            zl[0] = k[1] * l - k[3] * yl + zl[1]
            zl[1] = k[2] * l - k[4] * yl
            let yr = k[0] * r + zl[2]
            zl[2] = k[1] * r - k[3] * yr + zl[3]
            zl[3] = k[2] * r - k[4] * yr
            l = yl
            r = yr
        }

        if driveAmount > 0 {
            let amount = 1 + driveAmount * 4
            l = tanh(l * amount) * driveNorm
            r = tanh(r * amount) * driveNorm
        }

        if width != 1 {
            let mid = (l + r) * 0.5
            let side = (l - r) * 0.5 * width
            l = mid + side
            r = mid - side
        }

        if wet > 0, let reverb {
            let (wl, wr) = reverb.process((l + r) * 0.5)
            l = l * (1 - wet * 0.5) + wl * wet
            r = r * (1 - wet * 0.5) + wr * wet
        }

        if ratio > 1 {
            let level = max(abs(l), abs(r))
            let coeff = level > envelope ? attack : release
            envelope = coeff * envelope + (1 - coeff) * level
            let threshold: Float = 0.1 // -20 dBFS
            var gain = makeup
            if envelope > threshold {
                gain *= pow(envelope / threshold, 1 / ratio - 1)
            }
            l *= gain
            r *= gain
        }

        left = l
        right = r
    }

    private func setPeaking(_ c: UnsafeMutablePointer<Float>, frequency: Double, gain: Double) {
        guard abs(gain) >= 0.05 else { return setUnity(c) }
        let w0 = 2 * Double.pi * min(frequency, sampleRate * 0.45) / sampleRate
        let a = pow(10, gain / 40)
        let alpha = sin(w0) / (2 * 1.41)
        let a0 = 1 + alpha / a
        c[0] = Float((1 + alpha * a) / a0)
        c[1] = Float(-2 * cos(w0) / a0)
        c[2] = Float((1 - alpha * a) / a0)
        c[3] = Float(-2 * cos(w0) / a0)
        c[4] = Float((1 - alpha / a) / a0)
    }

    private func setPass(_ c: UnsafeMutablePointer<Float>, frequency: Double, highpass: Bool) {
        guard frequency > 0 else { return setUnity(c) }
        let w0 = 2 * Double.pi * min(frequency, sampleRate * 0.45) / sampleRate
        let alpha = sin(w0) / (2 * 0.707)
        let cosw = cos(w0)
        let a0 = 1 + alpha
        if highpass {
            c[0] = Float((1 + cosw) / 2 / a0)
            c[1] = Float(-(1 + cosw) / a0)
            c[2] = c[0]
        } else {
            c[0] = Float((1 - cosw) / 2 / a0)
            c[1] = Float((1 - cosw) / a0)
            c[2] = c[0]
        }
        c[3] = Float(-2 * cosw / a0)
        c[4] = Float((1 - alpha) / a0)
    }

    private func setUnity(_ c: UnsafeMutablePointer<Float>) {
        c[0] = 1; c[1] = 0; c[2] = 0; c[3] = 0; c[4] = 0
    }
}

/// Peak limiter with instant attack and a soft clip safety net. Used for boost.
struct Limiter {
    private var envelope: Float = 0
    private let release: Float = 0.9997
    private let ceiling: Float = 0.95

    @inline(__always)
    mutating func process(_ left: inout Float, _ right: inout Float) {
        let peak = max(abs(left), abs(right))
        envelope = peak > envelope ? peak : envelope * release
        if envelope > ceiling {
            let gain = ceiling / envelope
            left *= gain
            right *= gain
        }
        left = Self.softClip(left)
        right = Self.softClip(right)
    }

    @inline(__always)
    private static func softClip(_ x: Float) -> Float {
        let m = abs(x)
        guard m > 0.97 else { return x }
        let y = 0.97 + 0.03 * tanh((m - 0.97) / 0.03)
        return x < 0 ? -y : y
    }
}

// MARK: - Reverb (Freeverb)

private final class Reverb {
    private struct Line {
        let buffer: UnsafeMutablePointer<Float>
        let size: Int
        var index = 0
        var store: Float = 0

        init(size: Int) {
            self.size = max(size, 1)
            buffer = .allocate(capacity: self.size)
            buffer.initialize(repeating: 0, count: self.size)
        }
    }

    private static let combTuning = [1116, 1188, 1277, 1356, 1422, 1491]
    private static let allpassTuning = [556, 441, 341]
    private static let spread = 23

    private var combsL: [Line]
    private var combsR: [Line]
    private var allpassL: [Line]
    private var allpassR: [Line]
    private var feedback: Float = 0.84
    private var damp: Float = 0.2

    init(sampleRate: Double) {
        let scale = sampleRate / 44100
        combsL = Self.combTuning.map { Line(size: Int(Double($0) * scale)) }
        combsR = Self.combTuning.map { Line(size: Int(Double($0 + Self.spread) * scale)) }
        allpassL = Self.allpassTuning.map { Line(size: Int(Double($0) * scale)) }
        allpassR = Self.allpassTuning.map { Line(size: Int(Double($0 + Self.spread) * scale)) }
    }

    deinit {
        (combsL + combsR + allpassL + allpassR).forEach { $0.buffer.deallocate() }
    }

    func configure(room: Float, damping: Float) {
        feedback = 0.7 + room * 0.28
        damp = damping * 0.4
    }

    @inline(__always)
    func process(_ input: Float) -> (Float, Float) {
        let x = input * 0.015
        var l: Float = 0
        var r: Float = 0
        for i in 0..<combsL.count {
            l += comb(&combsL[i], x)
            r += comb(&combsR[i], x)
        }
        for i in 0..<allpassL.count {
            l = allpass(&allpassL[i], l)
            r = allpass(&allpassR[i], r)
        }
        return (l * 3, r * 3)
    }

    @inline(__always)
    private func comb(_ line: inout Line, _ x: Float) -> Float {
        let out = line.buffer[line.index]
        line.store = out * (1 - damp) + line.store * damp
        line.buffer[line.index] = x + line.store * feedback
        line.index += 1
        if line.index >= line.size { line.index = 0 }
        return out
    }

    @inline(__always)
    private func allpass(_ line: inout Line, _ x: Float) -> Float {
        let delayed = line.buffer[line.index]
        line.buffer[line.index] = x + delayed * 0.5
        line.index += 1
        if line.index >= line.size { line.index = 0 }
        return delayed - x
    }
}
