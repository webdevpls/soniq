import AudioToolbox
import CoreAudio
import Foundation

struct AudioDevice: Identifiable, Hashable {
    let id: AudioObjectID
    let uid: String
    let name: String
    let transport: UInt32

    var isAirPods: Bool { name.lowercased().contains("airpods") }

    var inputSymbol: String {
        switch transport {
        case kAudioDeviceTransportTypeBuiltIn: return "laptopcomputer"
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE: return isAirPods ? "airpods" : "headphones"
        case kAudioDeviceTransportTypeContinuityCaptureWired, kAudioDeviceTransportTypeContinuityCaptureWireless: return "iphone"
        case kAudioDeviceTransportTypeVirtual, kAudioDeviceTransportTypeAggregate: return "waveform"
        default: return "mic.fill"
        }
    }

    var symbol: String {
        let lower = name.lowercased()
        if lower.contains("airpods max") { return "airpodsmax" }
        if lower.contains("airpods pro") { return "airpodspro" }
        if lower.contains("airpods") { return "airpods" }
        switch transport {
        case kAudioDeviceTransportTypeBuiltIn: return "speaker.wave.2.fill"
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE: return "headphones"
        case kAudioDeviceTransportTypeHDMI, kAudioDeviceTransportTypeDisplayPort: return "tv"
        case kAudioDeviceTransportTypeAirPlay: return "airplayaudio"
        case kAudioDeviceTransportTypeVirtual, kAudioDeviceTransportTypeAggregate: return "waveform"
        default: return "hifispeaker.fill"
        }
    }
}

/// A Core Audio client process (one app can own several, e.g. browser helpers).
struct AudioProcess {
    let objectID: AudioObjectID
    let pid: pid_t
    let bundleID: String?
    let isRunningOutput: Bool
}

enum AudioSystem {
    static var defaultOutputID: AudioObjectID {
        AudioObjectID.system.get(kAudioHardwarePropertyDefaultOutputDevice, as: AudioObjectID.self) ?? .unknown
    }

    static var defaultInputID: AudioObjectID {
        AudioObjectID.system.get(kAudioHardwarePropertyDefaultInputDevice, as: AudioObjectID.self) ?? .unknown
    }

    static func setDefaultOutput(_ id: AudioObjectID) {
        AudioObjectID.system.set(kAudioHardwarePropertyDefaultOutputDevice, to: id)
        AudioObjectID.system.set(kAudioHardwarePropertyDefaultSystemOutputDevice, to: id)
    }

    static func setDefaultInput(_ id: AudioObjectID) {
        AudioObjectID.system.set(kAudioHardwarePropertyDefaultInputDevice, to: id)
    }

    static func outputDevices() -> [AudioDevice] { devices(scope: kAudioObjectPropertyScopeOutput) }
    static func inputDevices() -> [AudioDevice] { devices(scope: kAudioObjectPropertyScopeInput) }

    private static func devices(scope: AudioObjectPropertyScope) -> [AudioDevice] {
        let ids: [AudioObjectID] = AudioObjectID.system.getArray(kAudioHardwarePropertyDevices)
        return ids.compactMap { id in
            let streams: [AudioStreamID] = id.getArray(kAudioDevicePropertyStreams, scope: scope)
            guard !streams.isEmpty,
                  let uid = id.getString(kAudioDevicePropertyDeviceUID),
                  !uid.hasPrefix(AppTap.aggregateUIDPrefix),
                  id.get(kAudioDevicePropertyIsHidden, as: UInt32.self) != 1
            else { return nil }
            return AudioDevice(
                id: id,
                uid: uid,
                name: id.getString(kAudioObjectPropertyName) ?? "Unknown Device",
                transport: id.get(kAudioDevicePropertyTransportType, as: UInt32.self) ?? 0
            )
        }
    }

    // MARK: Device volume (output or input scope)

    static func volume(of device: AudioObjectID, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeOutput) -> Float? {
        device.get(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, scope: scope, as: Float32.self)
    }

    static func canSetVolume(of device: AudioObjectID, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeOutput) -> Bool {
        device.isSettable(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, scope: scope)
    }

    static func setVolume(_ value: Float, of device: AudioObjectID, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeOutput) {
        device.set(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, scope: scope, to: Float32(value))
    }

    static func isMuted(_ device: AudioObjectID, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeOutput) -> Bool {
        device.get(kAudioDevicePropertyMute, scope: scope, as: UInt32.self) == 1
    }

    static func setMuted(_ muted: Bool, _ device: AudioObjectID, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeOutput) {
        device.set(kAudioDevicePropertyMute, scope: scope, to: UInt32(muted ? 1 : 0))
    }

    // MARK: Processes

    static func processes() -> [AudioProcess] {
        let ids: [AudioObjectID] = AudioObjectID.system.getArray(kAudioHardwarePropertyProcessObjectList)
        return ids.compactMap { id in
            guard let pid = id.get(kAudioProcessPropertyPID, as: pid_t.self) else { return nil }
            return AudioProcess(
                objectID: id,
                pid: pid,
                bundleID: id.getString(kAudioProcessPropertyBundleID),
                isRunningOutput: id.get(kAudioProcessPropertyIsRunningOutput, as: UInt32.self) == 1
            )
        }
    }
}
