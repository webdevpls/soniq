import AudioToolbox
import CoreAudio
import Foundation

extension AudioObjectID {
    static let system = AudioObjectID(kAudioObjectSystemObject)
    static let unknown = AudioObjectID(kAudioObjectUnknown)

    private func address(
        _ selector: AudioObjectPropertySelector,
        _ scope: AudioObjectPropertyScope
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    func has(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> Bool {
        var addr = address(selector, scope)
        return AudioObjectHasProperty(self, &addr)
    }

    func isSettable(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> Bool {
        var addr = address(selector, scope)
        var settable: DarwinBoolean = false
        guard has(selector, scope: scope),
              AudioObjectIsPropertySettable(self, &addr, &settable) == noErr else { return false }
        return settable.boolValue
    }

    func get<T>(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, as _: T.Type) -> T? {
        guard has(selector, scope: scope) else { return nil }
        var addr = address(selector, scope)
        var size = UInt32(MemoryLayout<T>.size)
        let ptr = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { ptr.deallocate() }
        guard AudioObjectGetPropertyData(self, &addr, 0, nil, &size, ptr) == noErr else { return nil }
        return ptr.pointee
    }

    func getArray<T>(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> [T] {
        var addr = address(selector, scope)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(self, &addr, 0, nil, &size) == noErr, size > 0 else { return [] }
        let count = Int(size) / MemoryLayout<T>.stride
        return [T](unsafeUninitializedCapacity: count) { buffer, initialized in
            var readSize = size
            let status = AudioObjectGetPropertyData(self, &addr, 0, nil, &readSize, buffer.baseAddress!)
            initialized = status == noErr ? Int(readSize) / MemoryLayout<T>.stride : 0
        }
    }

    func getString(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> String? {
        guard has(selector, scope: scope) else { return nil }
        var addr = address(selector, scope)
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var value: Unmanaged<CFString>?
        let status = withUnsafeMutablePointer(to: &value) {
            AudioObjectGetPropertyData(self, &addr, 0, nil, &size, $0)
        }
        guard status == noErr, let value else { return nil }
        return value.takeRetainedValue() as String
    }

    @discardableResult
    func set<T>(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, to value: T) -> OSStatus {
        var addr = address(selector, scope)
        return withUnsafePointer(to: value) {
            AudioObjectSetPropertyData(self, &addr, 0, nil, UInt32(MemoryLayout<T>.size), $0)
        }
    }

    /// Registers a listener on the main queue. Returns a token that removes it.
    func listen(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        handler: @escaping () -> Void
    ) -> PropertyListener? {
        var addr = address(selector, scope)
        let block: AudioObjectPropertyListenerBlock = { _, _ in handler() }
        guard AudioObjectAddPropertyListenerBlock(self, &addr, .main, block) == noErr else { return nil }
        return PropertyListener(object: self, address: addr, block: block)
    }
}

final class PropertyListener {
    private let object: AudioObjectID
    private var address: AudioObjectPropertyAddress
    private let block: AudioObjectPropertyListenerBlock

    init(object: AudioObjectID, address: AudioObjectPropertyAddress, block: @escaping AudioObjectPropertyListenerBlock) {
        self.object = object
        self.address = address
        self.block = block
    }

    deinit {
        AudioObjectRemovePropertyListenerBlock(object, &address, .main, block)
    }
}
