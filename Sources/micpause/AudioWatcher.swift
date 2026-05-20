import CoreAudio
import Foundation

final class AudioWatcher {
    private var deviceStates: [AudioDeviceID: Bool] = [:]
    private var listeners: [AudioDeviceID: AudioObjectPropertyListenerBlock] = [:]
    private let queue = DispatchQueue(label: "micpause.audiowatcher")
    private let onAggregateChange: (Bool) -> Void

    init(onAggregateChange: @escaping (Bool) -> Void) {
        self.onAggregateChange = onAggregateChange
    }

    func start() {
        refreshDevices()
        registerDevicesTopologyListener()
    }

    private func registerDevicesTopologyListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.refreshDevices()
        }
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &address, queue, block
        )
    }

    private func refreshDevices() {
        let inputDevices = allInputDevices()
        let known = Set(listeners.keys)
        let current = Set(inputDevices)

        for id in current.subtracting(known) {
            attachListener(to: id)
        }
        for id in known.subtracting(current) {
            detachListener(from: id)
            deviceStates.removeValue(forKey: id)
        }
        recomputeAggregate()
    }

    private func attachListener(to deviceID: AudioDeviceID) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        deviceStates[deviceID] = readIsRunning(deviceID)
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self = self else { return }
            let running = self.readIsRunning(deviceID)
            self.deviceStates[deviceID] = running
            self.recomputeAggregate()
        }
        listeners[deviceID] = block
        AudioObjectAddPropertyListenerBlock(deviceID, &address, queue, block)
    }

    private func detachListener(from deviceID: AudioDeviceID) {
        guard let block = listeners.removeValue(forKey: deviceID) else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectRemovePropertyListenerBlock(deviceID, &address, queue, block)
    }

    private func recomputeAggregate() {
        let anyRunning = deviceStates.values.contains(true)
        onAggregateChange(anyRunning)
    }

    private func readIsRunning(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
        guard status == noErr else { return false }
        return value != 0
    }

    private func allInputDevices() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size
        )
        guard status == noErr else { return [] }
        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids
        )
        guard status == noErr else { return [] }
        return ids.filter { hasInputStreams($0) }
    }

    private func hasInputStreams(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size)
        guard status == noErr else { return false }
        return size > 0
    }
}
