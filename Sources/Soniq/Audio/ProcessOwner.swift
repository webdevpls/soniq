import AppKit
import Darwin

/// Resolves audio helper processes (Chrome helpers, WebKit GPU process, ...) to the app the user sees.
enum ProcessOwner {
    private typealias ResponsibleFn = @convention(c) (pid_t) -> pid_t

    private static let responsiblePID: ResponsibleFn? = {
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "responsibility_get_pid_responsible_for_pid") else { return nil }
        return unsafeBitCast(symbol, to: ResponsibleFn.self)
    }()

    static func app(for pid: pid_t) -> NSRunningApplication? {
        if let app = NSRunningApplication(processIdentifier: pid), app.activationPolicy == .regular {
            return app
        }
        if let responsiblePID {
            let owner = responsiblePID(pid)
            if owner > 0, owner != pid, let app = NSRunningApplication(processIdentifier: owner), app.bundleURL != nil {
                return app
            }
        }
        var current = pid
        for _ in 0..<8 {
            let parent = parentPID(of: current)
            guard parent > 1 else { break }
            if let app = NSRunningApplication(processIdentifier: parent), app.activationPolicy == .regular {
                return app
            }
            current = parent
        }
        return NSRunningApplication(processIdentifier: pid)
    }

    private static func parentPID(of pid: pid_t) -> pid_t {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0 else { return 0 }
        return info.kp_eproc.e_ppid
    }
}
