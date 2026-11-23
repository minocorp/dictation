import CoreAudio

internal enum AudioDeviceDirectory {
    static func inputDevices() -> [InputDeviceDescription] {
        deviceIDs()
            .compactMap { id in
                guard inputChannelCount(of: id) > 0, let uid = uid(of: id) else { return nil }
                let transport: UInt32? = value(
                    of: id,
                    kAudioDevicePropertyTransportType,
                    initial: 0,
                )
                return InputDeviceDescription(
                    id: id,
                    uid: uid,
                    isBuiltIn: transport == kAudioDeviceTransportTypeBuiltIn,
                )
            }
    }

    static func defaultInputID() -> UInt32? {
        let id: UInt32? = value(
            of: AudioObjectID(kAudioObjectSystemObject),
            kAudioHardwarePropertyDefaultInputDevice,
            initial: 0,
        )
        return id.flatMap { $0 == kAudioObjectUnknown ? nil : $0 }
    }

    static func nominalSampleRate(of id: UInt32) -> Double? {
        value(of: id, kAudioDevicePropertyNominalSampleRate, initial: Float64(0))
    }

    private static func deviceIDs() -> [AudioDeviceID] {
        var address = address(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else {
            return []
        }
        var ids = [AudioDeviceID](
            repeating: 0,
            count: Int(size) / MemoryLayout<AudioDeviceID>.size,
        )
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else {
            return []
        }
        return ids
    }

    private static func inputChannelCount(of id: AudioDeviceID) -> Int {
        var address = address(
            kAudioDevicePropertyStreamConfiguration,
            scope: kAudioObjectPropertyScopeInput,
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr, size > 0 else {
            return 0
        }
        let storage = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size),
            alignment: MemoryLayout<AudioBufferList>.alignment,
        )
        defer { storage.deallocate() }
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, storage) == noErr else {
            return 0
        }
        let list = UnsafeMutableAudioBufferListPointer(
            storage.assumingMemoryBound(to: AudioBufferList.self)
        )
        return list.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private static func uid(of id: AudioDeviceID) -> String? {
        var address = address(kAudioDevicePropertyDeviceUID)
        var uid: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &uid) == noErr else {
            return nil
        }
        return uid?.takeRetainedValue() as String?
    }

    private static func value<Value: BitwiseCopyable>(
        of object: AudioObjectID,
        _ selector: AudioObjectPropertySelector,
        initial: Value,
    ) -> Value? {
        var address = address(selector)
        var result = initial
        var size = UInt32(MemoryLayout<Value>.size)
        guard AudioObjectGetPropertyData(object, &address, 0, nil, &size, &result) == noErr else {
            return nil
        }
        return result
    }

    private static func address(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain,
        )
    }
}
