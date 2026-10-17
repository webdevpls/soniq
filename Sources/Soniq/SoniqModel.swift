import AppKit
import AudioToolbox
import Combine
import CoreAudio
import ServiceManagement

struct MixerApp: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: NSImage
    var isPlaying: Bool

    static func == (lhs: MixerApp, rhs: MixerApp) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.isPlaying == rhs.isPlaying
    }
}

final class SoniqModel: ObservableObject {
    /// Apps that use audio. Playing apps first.
    @Published private(set) var apps: [MixerApp] = []
    @Published private(set) var permission = AudioCapturePermission.status

    // Output
    @Published private(set) var outputs: [AudioDevice] = []
    @Published private(set) var outputID = AudioObjectID.unknown
    @Published private(set) var hardwareVolume: Float = 0
    @Published private(set) var outputMuted = false
    @Published private(set) var outputAdjustable = false
    /// Software gain on top of the hardware volume, 1 … 2.
    @Published private(set) var boost: Float

    // Input
    @Published private(set) var inputs: [AudioDevice] = []
    @Published private(set) var inputID = AudioObjectID.unknown
    @Published private(set) var inputVolume: Float = 0
    @Published private(set) var inputMuted = false
    @Published private(set) var inputAdjustable = false
    /// Keep the chosen mic even when headphones with a mic connect.
    @Published private(set) var lockInput: Bool
    private var preferredInputUID: String?
    /// Keep the mic level the user chose: call and browser apps raise it with automatic gain control.
    @Published private(set) var lockInputLevel: Bool
    private var inputLevels: [String: Float]

    // Per app
    @Published private(set) var volumes: [String: Float]
    @Published private(set) var balances: [String: Float]
    @Published private(set) var mutedApps: Set<String>

    // Effects
    @Published private(set) var effectID: String
    @Published private(set) var intensity: Float
    @Published private(set) var bass: Float
    @Published private(set) var treble: Float

    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled {
        didSet { updateLoginItem() }
    }

    /// Apps known to never make sound; hidden from the list unless they actually play.
    private static let silentApps: Set<String> = [
        "com.apple.finder", "com.apple.iCal", "com.apple.Preview", "com.apple.Terminal",
        "com.figma.Desktop", "com.apple.systempreferences", "com.apple.ActivityMonitor",
        "com.apple.TextEdit", "com.apple.Notes", "com.apple.reminders", "com.apple.AddressBook",
        "com.apple.dt.Xcode", "com.googlecode.iterm2", "com.apple.calculator", "com.apple.Passwords",
    ]

    private let lingerInterval: TimeInterval = 30
    /// Keep effect/boost taps alive across short pauses so resuming doesn't glitch.
    private let globalTapInterval: TimeInterval = 300

    private var taps: [String: AppTap] = [:]
    private var failedTaps: [String: Set<AudioObjectID>] = [:]
    private var groups: [String: [AudioObjectID]] = [:]
    private var lastPlayed: [String: Date] = [:]
    private var owners: [pid_t: NSRunningApplication?] = [:]
    private var systemListeners: [PropertyListener] = []
    private var outputListeners: [PropertyListener] = []
    private var inputListeners: [PropertyListener] = []
    private var askedForPermission = false
    private var timer: Timer?
    private let ownPID = ProcessInfo.processInfo.processIdentifier
    private let defaults = UserDefaults.standard
    private let debug = ProcessInfo.processInfo.environment["SONIQ_DEBUG"] != nil

    init() {
        volumes = (defaults.dictionary(forKey: "volumes") as? [String: Double])?.mapValues(Float.init) ?? [:]
        balances = (defaults.dictionary(forKey: "balances") as? [String: Double])?.mapValues(Float.init) ?? [:]
        mutedApps = Set(defaults.stringArray(forKey: "mutedApps") ?? [])
        boost = Float(defaults.object(forKey: "boost") as? Double ?? 1)
        effectID = defaults.string(forKey: "effect") ?? SoundEffect.off.id
        intensity = Float(defaults.object(forKey: "intensity") as? Double ?? 1)
        bass = Float(defaults.double(forKey: "bass"))
        treble = Float(defaults.double(forKey: "treble"))
        lockInput = defaults.bool(forKey: "lockInput")
        lockInputLevel = defaults.object(forKey: "lockInputLevel") as? Bool ?? true
        inputLevels = (defaults.dictionary(forKey: "inputLevels") as? [String: Double])?.mapValues(Float.init) ?? [:]
        preferredInputUID = defaults.string(forKey: "preferredInput")

        refreshOutput()
        refreshInput()
        refreshApps()
        if debug { NSLog("Soniq: audio capture permission \(permission)") }

        systemListeners = [
            AudioObjectID.system.listen(kAudioHardwarePropertyDefaultOutputDevice) { [weak self] in self?.refreshOutput() },
            AudioObjectID.system.listen(kAudioHardwarePropertyDefaultInputDevice) { [weak self] in self?.refreshInput() },
            AudioObjectID.system.listen(kAudioHardwarePropertyDevices) { [weak self] in
                self?.refreshOutput()
                self?.refreshInput()
            },
            AudioObjectID.system.listen(kAudioHardwarePropertyProcessObjectList) { [weak self] in self?.refreshApps() },
        ].compactMap { $0 }

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.refreshApps() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.taps.values.forEach { $0.invalidate() }
            self?.taps.removeAll()
        }
    }

    // MARK: Apps

    func volume(for id: String) -> Float { volumes[id] ?? 1 }
    func balance(for id: String) -> Float { balances[id] ?? 0 }
    func isMuted(_ id: String) -> Bool { mutedApps.contains(id) }

    func setVolume(_ value: Float, for id: String) {
        volumes[id] = value
        mutedApps.remove(id)
        updateTap(id)
        save()
    }

    func setBalance(_ value: Float, for id: String) {
        balances[id] = abs(value) < 0.04 ? 0 : value
        updateTap(id)
        save()
    }

    func toggleMute(_ id: String) {
        if mutedApps.contains(id) { mutedApps.remove(id) } else { mutedApps.insert(id) }
        updateTap(id)
        save()
    }

    private func updateTap(_ id: String) {
        if let tap = taps[id] {
            tap.gain = gain(for: id)
            tap.balance = balance(for: id)
        }
        syncTaps()
    }

    private func gain(for id: String) -> Float {
        (mutedApps.contains(id) ? 0 : volume(for: id)) * boost
    }

    private func refreshApps() {
        let now = Date()
        let processes = AudioSystem.processes().filter { $0.pid != ownPID }
        let livePIDs = Set(processes.map(\.pid))
        owners = owners.filter { livePIDs.contains($0.key) }

        var newGroups: [String: [AudioObjectID]] = [:]
        var playing: Set<String> = []
        var entries: [String: MixerApp] = [:]

        for process in processes {
            if owners[process.pid] == nil { owners[process.pid] = ProcessOwner.app(for: process.pid) }
            // Only real apps belong in the mixer; system daemons are skipped.
            guard let owner = owners[process.pid] ?? nil,
                  let bundleURL = owner.bundleURL, bundleURL.pathExtension == "app",
                  !bundleURL.path.hasPrefix("/System/Library/"),
                  let key = owner.bundleIdentifier ?? process.bundleID,
                  key != Bundle.main.bundleIdentifier
            else { continue }

            newGroups[key, default: []].append(process.objectID)
            if process.isRunningOutput {
                playing.insert(key)
                lastPlayed[key] = now
            }
            if entries[key] == nil {
                entries[key] = MixerApp(id: key, name: owner.localizedName ?? key,
                                        icon: owner.icon ?? NSWorkspace.shared.icon(for: .application), isPlaying: false)
            }
        }

        groups = newGroups
        lastPlayed = lastPlayed.filter { newGroups[$0.key] != nil }

        let visible = entries.values
            .filter { app in
                playing.contains(app.id) || !Self.silentApps.contains(app.id)
                    || recentlyPlayed(app.id, within: lingerInterval, now: now)
            }
            .map { app -> MixerApp in
                var app = app
                app.isPlaying = playing.contains(app.id)
                return app
            }
            .sorted {
                if $0.isPlaying != $1.isPlaying { return $0.isPlaying }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        if visible != apps { apps = visible }
        syncTaps()

        if debug {
            for (key, tap) in taps { NSLog("Soniq: \(key) peak=\(tap.takePeak())") }
        }
    }

    private func recentlyPlayed(_ key: String, within interval: TimeInterval, now: Date = Date()) -> Bool {
        lastPlayed[key].map { now.timeIntervalSince($0) < interval } ?? false
    }

    /// Creates, updates or tears down taps to match each app's gain, balance and the global effects.
    /// Untouched apps get no tap at all, so Soniq costs nothing until you use it.
    private func syncTaps() {
        guard let outputUID = outputID.getString(kAudioDevicePropertyDeviceUID) else { return }
        let settings = dspSettings
        let global = boost > 1.001 || !settings.isNeutral

        let wanted = groups.filter { key, _ in
            abs(gain(for: key) - 1) > 0.001 || balance(for: key) != 0
                || (global && recentlyPlayed(key, within: globalTapInterval))
        }

        // Without permission a tap mutes the app and delivers silence, so never create one.
        guard wanted.isEmpty || hasPermission() else {
            taps.values.forEach { $0.invalidate() }
            taps.removeAll()
            return
        }

        for (key, tap) in taps where wanted[key] == nil {
            tap.invalidate()
            taps[key] = nil
        }

        for (key, objects) in wanted {
            let objectSet = Set(objects)
            if let tap = taps[key], tap.processObjects == objectSet, tap.outputUID == outputUID {
                tap.gain = gain(for: key)
                tap.balance = balance(for: key)
                continue
            }
            if failedTaps[key] == objectSet { continue }

            taps.removeValue(forKey: key)?.invalidate()
            let tap = AppTap(processObjects: objects, outputUID: outputUID, gain: gain(for: key),
                             balance: balance(for: key), settings: settings)
            do {
                try tap.start()
                taps[key] = tap
                failedTaps[key] = nil
            } catch {
                tap.invalidate()
                failedTaps[key] = objectSet
                NSLog("Soniq: could not control \(key): \(error)")
            }
        }
    }

    /// Asks for System Audio Recording at most once per launch. macOS itself only shows
    /// the prompt the first time; after that the stored answer is used.
    private func hasPermission() -> Bool {
        if permission == .granted { return true }
        let status = AudioCapturePermission.status
        if status != permission { permission = status }
        switch status {
        case .granted:
            return true
        case .denied:
            return false
        case .unknown:
            guard !askedForPermission else { return false }
            askedForPermission = true
            AudioCapturePermission.request { [weak self] granted in
                guard let self else { return }
                permission = granted ? .granted : .denied
                syncTaps()
            }
            return false
        }
    }

    func requestPermission() {
        if permission == .denied { AudioCapturePermission.openSettings() } else { askedForPermission = false; _ = hasPermission() }
    }

    // MARK: Effects

    var effect: SoundEffect { SoundEffect.all.first { $0.id == effectID } ?? .off }

    private var dspSettings: DSPSettings {
        DSPSettings.make(effect: effect, intensity: intensity, bass: bass, treble: treble)
    }

    func selectEffect(_ id: String) {
        effectID = id
        applyEffects()
    }

    func setIntensity(_ value: Float) { intensity = value; applyEffects() }
    func setBass(_ value: Float) { bass = abs(value) < 0.3 ? 0 : value; applyEffects() }
    func setTreble(_ value: Float) { treble = abs(value) < 0.3 ? 0 : value; applyEffects() }

    private func applyEffects() {
        let settings = dspSettings
        taps.values.forEach { $0.setEffects(settings) }
        syncTaps()
        save()
    }

    // MARK: Output

    var output: AudioDevice? { outputs.first { $0.id == outputID } }

    /// 0 … 2: up to 1 drives the device volume, above 1 is software boost.
    var outputLevel: Float { boost > 1.001 ? boost : hardwareVolume }

    func setOutputLevel(_ value: Float) {
        if value <= 1 {
            boost = 1
            if outputAdjustable { AudioSystem.setVolume(value, of: outputID) }
            hardwareVolume = value
        } else {
            if hardwareVolume < 1, outputAdjustable { AudioSystem.setVolume(1, of: outputID) }
            hardwareVolume = 1
            boost = value
        }
        // Volume 0 isn't always silent on every device, so the bottom of the slider mutes too.
        let silent = value < 0.01
        if silent != outputMuted {
            AudioSystem.setMuted(silent, outputID)
            outputMuted = silent
        }
        taps.forEach { key, tap in tap.gain = gain(for: key) }
        syncTaps()
        save()
    }

    func toggleOutputMute() {
        AudioSystem.setMuted(!outputMuted, outputID)
        refreshOutputLevel()
    }

    func selectOutput(_ device: AudioDevice) {
        AudioSystem.setDefaultOutput(device.id)
    }

    private func refreshOutput() {
        outputs = AudioSystem.outputDevices()
        let current = AudioSystem.defaultOutputID
        guard current != outputID else { return refreshOutputLevel() }

        outputID = current
        outputListeners = [kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioDevicePropertyMute].compactMap {
            current.listen($0, scope: kAudioObjectPropertyScopeOutput) { [weak self] in self?.refreshOutputLevel() }
        }
        refreshOutputLevel()

        // Taps play through the default output, so rebuild them on the new device.
        taps.values.forEach { $0.invalidate() }
        taps.removeAll()
        failedTaps.removeAll()
        syncTaps()
    }

    private func refreshOutputLevel() {
        outputAdjustable = AudioSystem.canSetVolume(of: outputID)
        hardwareVolume = AudioSystem.volume(of: outputID) ?? 1
        outputMuted = AudioSystem.isMuted(outputID)
        // Turning the volume down with the keyboard ends boost.
        if hardwareVolume < 0.999 && boost > 1 {
            boost = 1
            taps.forEach { key, tap in tap.gain = gain(for: key) }
            syncTaps()
        }
    }

    // MARK: Input

    var input: AudioDevice? { inputs.first { $0.id == inputID } }

    func selectInput(_ device: AudioDevice) {
        preferredInputUID = device.uid
        AudioSystem.setDefaultInput(device.id)
        save()
    }

    func setLockInput(_ locked: Bool) {
        lockInput = locked
        if locked, preferredInputUID == nil { preferredInputUID = input?.uid }
        save()
        refreshInput()
    }

    /// Many mics only go down to about -32 dB, so the bottom of the slider also mutes the device.
    func setInputVolume(_ value: Float) {
        guard inputAdjustable else { return }
        let scope = kAudioObjectPropertyScopeInput
        let silent = value < 0.01
        inputVolume = silent ? 0 : value
        AudioSystem.setVolume(inputVolume, of: inputID, scope: scope)
        if let uid = input?.uid { inputLevels[uid] = inputVolume }
        if silent != inputMuted {
            AudioSystem.setMuted(silent, inputID, scope: scope)
            inputMuted = silent
        }
        save()
    }

    func setLockInputLevel(_ locked: Bool) {
        lockInputLevel = locked
        if locked, let uid = input?.uid, inputLevels[uid] == nil { inputLevels[uid] = inputVolume }
        save()
    }

    func toggleInputMute() {
        let scope = kAudioObjectPropertyScopeInput
        let mute = !inputMuted
        AudioSystem.setMuted(mute, inputID, scope: scope)
        // Unmuting from the bottom of the slider would stay silent, so bring the level back up.
        if !mute && inputVolume < 0.01 && inputAdjustable {
            AudioSystem.setVolume(0.5, of: inputID, scope: scope)
        }
        refreshInputLevel()
    }

    private func refreshInput() {
        inputs = AudioSystem.inputDevices()
        let current = AudioSystem.defaultInputID

        // macOS switches to a headset mic when it connects; switch back if the user locked their choice.
        if lockInput, let preferred = inputs.first(where: { $0.uid == preferredInputUID }), preferred.id != current {
            AudioSystem.setDefaultInput(preferred.id)
            return
        }

        guard current != inputID else { return refreshInputLevel() }
        inputID = current
        inputListeners = [kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioDevicePropertyMute].compactMap {
            current.listen($0, scope: kAudioObjectPropertyScopeInput) { [weak self] in self?.refreshInputLevel() }
        }
        refreshInputLevel()
    }

    private func refreshInputLevel() {
        let scope = kAudioObjectPropertyScopeInput
        inputAdjustable = AudioSystem.canSetVolume(of: inputID, scope: scope)
        let current = AudioSystem.volume(of: inputID, scope: scope) ?? 1
        inputMuted = AudioSystem.isMuted(inputID, scope: scope)

        if lockInputLevel, inputAdjustable, let uid = input?.uid, inputLevels[uid] == nil {
            inputLevels[uid] = current
            save()
        }
        // Another app changed the level: put the user's choice back.
        if lockInputLevel, inputAdjustable, let uid = input?.uid, let wanted = inputLevels[uid], abs(current - wanted) > 0.015 {
            AudioSystem.setVolume(wanted, of: inputID, scope: scope)
            inputVolume = wanted
        } else {
            inputVolume = current
        }
    }

    // MARK: Persistence & login item

    private func save() {
        defaults.set(volumes.mapValues(Double.init), forKey: "volumes")
        defaults.set(balances.mapValues(Double.init), forKey: "balances")
        defaults.set(Array(mutedApps), forKey: "mutedApps")
        defaults.set(Double(boost), forKey: "boost")
        defaults.set(effectID, forKey: "effect")
        defaults.set(Double(intensity), forKey: "intensity")
        defaults.set(Double(bass), forKey: "bass")
        defaults.set(Double(treble), forKey: "treble")
        defaults.set(lockInput, forKey: "lockInput")
        defaults.set(preferredInputUID, forKey: "preferredInput")
        defaults.set(lockInputLevel, forKey: "lockInputLevel")
        defaults.set(inputLevels.mapValues(Double.init), forKey: "inputLevels")
    }

    private func updateLoginItem() {
        do {
            if launchAtLogin { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Soniq: login item update failed: \(error)")
        }
    }
}
