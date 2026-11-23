import Core
import Testing
@testable import UI

internal struct HUDAnnouncementTests {
    struct Case {
        let previous: HUDState
        let current: HUDState
        let expected: HUDAnnouncement?
    }

    static let cases = [
        Case(previous: .hidden, current: .listening, expected: .listening),
        Case(
            previous: .listening,
            current: .handsFree(elapsed: .zero, countdown: nil),
            expected: .handsFree,
        ),
        Case(
            previous: .handsFree(elapsed: .seconds(1), countdown: nil),
            current: .handsFree(elapsed: .seconds(2), countdown: nil),
            expected: nil,
        ),
        Case(
            previous: .handsFree(elapsed: .seconds(110), countdown: nil),
            current: .handsFree(elapsed: .seconds(111), countdown: .seconds(10)),
            expected: .handsFreeEnding,
        ),
        Case(
            previous: .handsFree(elapsed: .seconds(111), countdown: .seconds(10)),
            current: .handsFree(elapsed: .seconds(112), countdown: .seconds(9)),
            expected: nil,
        ),
        Case(previous: .listening, current: .editing, expected: .editing),
        Case(previous: .listening, current: .processing, expected: .processing),
        Case(previous: .processing, current: .copied, expected: .copied),
        Case(previous: .processing, current: .canceled, expected: .canceled),
        Case(previous: .processing, current: .saved, expected: .saved),
        Case(previous: .processing, current: .noSpeech, expected: .noSpeech),
        Case(previous: .copied, current: .hidden, expected: nil),
        Case(
            previous: .hidden,
            current: .problem(.accessibilityOff),
            expected: .problem(.accessibilityOff),
        ),
        Case(
            previous: .problem(.accessibilityOff),
            current: .problem(.accessibilityOff),
            expected: nil,
        ),
        Case(
            previous: .problem(.accessibilityOff),
            current: .problem(.microphoneDenied),
            expected: .problem(.microphoneDenied),
        ),
    ]

    @Test(arguments: cases)
    func announcesOncePerStateChange(testCase: Case) {
        #expect(HUDAnnouncement.between(testCase.previous, testCase.current) == testCase.expected)
    }

    @Test
    func problemWithAFixMentionsTheButton() {
        let withFix = HUDAnnouncement.problem(.microphoneDenied).text
        let withoutFix = HUDAnnouncement.problem(.passwordField).text
        #expect(withFix.hasSuffix(UIString.string(UIString.a11yProblemOpensFix)))
        #expect(!withoutFix.contains(UIString.string(UIString.a11yProblemOpensFix)))
    }
}
