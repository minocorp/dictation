import Synchronization

// Producer and consumer coordinate only through the two atomic indices.
// swiftlint:disable:next no_unchecked_sendable
internal final class SPSCRingBuffer: @unchecked Sendable {
    let capacity: Int

    private let storage: UnsafeMutablePointer<Float>
    private let writeIndex = Atomic<Int>(0)
    private let readIndex = Atomic<Int>(0)

    init(capacity: Int) {
        self.capacity = max(capacity, 1)
        storage = .allocate(capacity: self.capacity)
        storage.initialize(repeating: 0, count: self.capacity)
    }

    deinit {
        storage.deallocate()
    }

    var availableToRead: Int {
        writeIndex.load(ordering: .acquiring) - readIndex.load(ordering: .relaxed)
    }

    func write(_ source: UnsafeBufferPointer<Float>, frameSize: Int = 1) -> Int {
        let write = writeIndex.load(ordering: .relaxed)
        let read = readIndex.load(ordering: .acquiring)
        let room = min(source.count, capacity - (write - read))
        let count = room - room % max(frameSize, 1)
        guard count > 0, let base = source.baseAddress else { return 0 }
        let offset = write % capacity
        let firstRun = min(count, capacity - offset)
        (storage + offset).update(from: base, count: firstRun)
        if count > firstRun {
            storage.update(from: base + firstRun, count: count - firstRun)
        }
        writeIndex.store(write + count, ordering: .releasing)
        return count
    }

    func read(into destination: UnsafeMutableBufferPointer<Float>) -> Int {
        let write = writeIndex.load(ordering: .acquiring)
        let read = readIndex.load(ordering: .relaxed)
        let count = min(destination.count, write - read)
        guard count > 0, let base = destination.baseAddress else { return 0 }
        let offset = read % capacity
        let firstRun = min(count, capacity - offset)
        base.update(from: storage + offset, count: firstRun)
        if count > firstRun {
            (base + firstRun).update(from: storage, count: count - firstRun)
        }
        readIndex.store(read + count, ordering: .releasing)
        return count
    }
}
