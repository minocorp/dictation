@testable import Learning
import Testing

internal struct WordDistanceTests {
    private struct Case: Sendable {
        let lhs: String
        let rhs: String
        let distance: Int
    }

    private static let cases = [
        Case(lhs: "", rhs: "", distance: 0),
        Case(lhs: "abc", rhs: "", distance: 3),
        Case(lhs: "", rhs: "abc", distance: 3),
        Case(lhs: "kitten", rhs: "sitting", distance: 3),
        Case(lhs: "superbase", rhs: "supabase", distance: 2),
        Case(lhs: "슈퍼", rhs: "수파", distance: 2),
        Case(lhs: "same", rhs: "same", distance: 0),
    ]

    @Test(arguments: cases)
    private func measuresEditDistance(testCase: Case) {
        #expect(WordDistance.levenshtein(testCase.lhs, testCase.rhs) == testCase.distance)
    }
}
