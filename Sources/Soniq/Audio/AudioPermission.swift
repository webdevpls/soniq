import AppKit

/// "System Audio Recording" (kTCCServiceAudioCapture) permission.
///
/// Without it a process tap delivers silence while still muting the app, so taps are
/// only created once access is granted. macOS has no public API for this permission,
/// so we use the TCC calls that the system itself uses for the prompt.
enum AudioCapturePermission {
    enum Status { case granted, denied, unknown }

    private typealias PreflightFn = @convention(c) (CFString, CFDictionary?) -> Int
    private typealias RequestFn = @convention(c) (CFString, CFDictionary?, @escaping @convention(block) (Bool) -> Void) -> Void

    private static let service = "kTCCServiceAudioCapture" as CFString
    private static let handle = dlopen("/System/Library/PrivateFrameworks/TCC.framework/Versions/A/TCC", RTLD_NOW)

    private static let preflight: PreflightFn? = handle
        .flatMap { dlsym($0, "TCCAccessPreflight") }
        .map { unsafeBitCast($0, to: PreflightFn.self) }

    private static let requestAccess: RequestFn? = handle
        .flatMap { dlsym($0, "TCCAccessRequest") }
        .map { unsafeBitCast($0, to: RequestFn.self) }

    static var status: Status {
        guard let preflight else { return .unknown }
        switch preflight(service, nil) {
        case 0: return .granted
        case 1: return .denied
        default: return .unknown
        }
    }

    static func request(_ completion: @escaping (Bool) -> Void) {
        guard let requestAccess else { return completion(false) }
        requestAccess(service, nil) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AudioCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
