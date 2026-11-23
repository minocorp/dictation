@testable import Capture
import Testing

internal struct SPSCRingBufferTests {
    @Test
    func readReturnsWrittenSamplesInOrder() {
        let ring = SPSCRingBuffer(capacity: 8)
        let input: [Float] = [1, 2, 3, 4, 5]
        let written = input.withUnsafeBufferPointer { ring.write($0) }
        var output = [Float](repeating: 0, count: 8)
        let read = output.withUnsafeMutableBufferPointer { ring.read(into: $0) }
        #expect(written == 5)
        #expect(read == 5)
        #expect(Array(output.prefix(5)) == input)
    }

    @Test
    func writeBeyondCapacityKeepsUnreadSamples() {
        let ring = SPSCRingBuffer(capacity: 4)
        let input: [Float] = [1, 2, 3, 4, 5, 6]
        let written = input.withUnsafeBufferPointer { ring.write($0) }
        var output = [Float](repeating: 0, count: 6)
        let read = output.withUnsafeMutableBufferPointer { ring.read(into: $0) }
        #expect(written == 4)
        #expect(read == 4)
        #expect(Array(output.prefix(4)) == [1, 2, 3, 4])
    }

    @Test
    func writeKeepsWholeFramesOnly() {
        let ring = SPSCRingBuffer(capacity: 5)
        let input: [Float] = [1, 2, 3, 4, 5, 6]
        let written = input.withUnsafeBufferPointer { ring.write($0, frameSize: 2) }
        var output = [Float](repeating: 0, count: 6)
        let read = output.withUnsafeMutableBufferPointer { ring.read(into: $0) }
        #expect(written == 4)
        #expect(read == 4)
        #expect(Array(output.prefix(4)) == [1, 2, 3, 4])
    }

    @Test
    func samplesSurviveWraparound() {
        let ring = SPSCRingBuffer(capacity: 5)
        var expected: [Float] = []
        var received: [Float] = []
        var next: Float = 0
        for round in 0..<20 {
            let batch = (0..<(round % 4 + 1))
                .map { _ in
                    defer { next += 1 }
                    return next
                }
            let written = batch.withUnsafeBufferPointer { ring.write($0) }
            expected.append(contentsOf: batch.prefix(written))
            var output = [Float](repeating: 0, count: 3)
            let read = output.withUnsafeMutableBufferPointer { ring.read(into: $0) }
            received.append(contentsOf: output.prefix(read))
        }
        var rest = [Float](repeating: 0, count: 5)
        let read = rest.withUnsafeMutableBufferPointer { ring.read(into: $0) }
        received.append(contentsOf: rest.prefix(read))
        #expect(received == expected)
        #expect(ring.availableToRead == 0)
    }

    @Test
    func concurrentProducerAndConsumerPreserveSequence() async {
        let ring = SPSCRingBuffer(capacity: 1_024)
        let total = 1_000_000
        let received = await withTaskGroup(of: [Float].self) { group in
            group.addTask { await Self.produce(total: total, into: ring) }
            group.addTask { await Self.consume(total: total, from: ring) }
            var consumed: [Float] = []
            for await result in group where !result.isEmpty {
                consumed = result
            }
            return consumed
        }
        #expect(received.count == total)
        #expect(received.enumerated().allSatisfy { $0.element == Float($0.offset) })
    }

    private static func produce(total: Int, into ring: SPSCRingBuffer) async -> [Float] {
        var next = 0
        while next < total {
            let size = min(total - next, 1 + next % 97)
            let batch = (next..<next + size).map { Float($0) }
            var offset = 0
            while offset < size {
                let written = batch[offset...].withUnsafeBufferPointer { ring.write($0) }
                offset += written
                if written == 0 { await Task.yield() }
            }
            next += size
        }
        return []
    }

    private static func consume(total: Int, from ring: SPSCRingBuffer) async -> [Float] {
        var received: [Float] = []
        received.reserveCapacity(total)
        var buffer = [Float](repeating: 0, count: 64)
        while received.count < total {
            let read = buffer.withUnsafeMutableBufferPointer { ring.read(into: $0) }
            received.append(contentsOf: buffer.prefix(read))
            if read == 0 { await Task.yield() }
        }
        return received
    }
}
