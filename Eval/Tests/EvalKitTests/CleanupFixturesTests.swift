@testable import EvalKit
import Foundation
import Testing

internal struct CleanupFixturesTests {
    private static let file = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Fixtures/disfluent.jsonl")

    @Test
    func fixturesLoadWithUniqueIds() throws {
        let cases = try CleanupCase.load(from: Self.file)
        #expect(cases.count >= 60)
        #expect(Set(cases.map(\.id)).count == cases.count)
    }

    @Test
    func everyRequiredCategoryIsPresent() throws {
        let categories = Set(try CleanupCase.load(from: Self.file).map(\.category))
        let required: Set = [
            "filler-ko", "filler-en", "selfcorrect-ko", "selfcorrect-en", "list", "numbers",
            "question-stay", "injection-stay", "already-clean", "mixed",
        ]
        #expect(required.isSubset(of: categories))
    }

    @Test
    func alreadyCleanCasesAreNoOps() throws {
        let cases = try CleanupCase.load(from: Self.file).filter { $0.category == "already-clean" }
        #expect(!cases.isEmpty)
        #expect(cases.allSatisfy { $0.isNoOp })
    }

    @Test
    func missingFileIsFixturesError() {
        #expect(throws: EvalError.self) {
            try CleanupCase.load(from: URL(fileURLWithPath: "/tmp/no-such-fixtures.jsonl"))
        }
    }
}
