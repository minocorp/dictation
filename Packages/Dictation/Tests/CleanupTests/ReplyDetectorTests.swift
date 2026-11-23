@testable import Cleanup
import Testing

internal struct ReplyDetectorTests {
    private let detector = ReplyDetector()

    @Test
    func anOpenerInTheMiddleOfTheInputDoesNotExcuseAnOutputOpener() {
        #expect(detector.hasReplyOpener("Okay, I moved it.", input: "he said okay and I moved it"))
    }

    @Test
    func anOpenerThatTheSpeakerStartedWithIsExcused() {
        #expect(!detector.hasReplyOpener("Okay, I moved it.", input: "okay I moved it"))
    }

    @Test
    func singleItemNumberedOutputIsForeignStructure() {
        #expect(detector.hasForeignStructure("1. Buy milk", input: "buy milk"))
        #expect(!detector.hasForeignStructure("1. Buy milk", input: "1. buy milk"))
    }
}
