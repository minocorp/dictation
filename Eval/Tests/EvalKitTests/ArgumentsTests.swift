@testable import EvalKit
import Testing

internal struct ArgumentsTests {
    @Test
    func parsesCommandAndFlags() throws {
        let arguments = try Arguments(["asr", "--model", "/m", "--limit", "20"])
        #expect(arguments.command == "asr")
        #expect(try arguments.required("model") == "/m")
        #expect(try arguments.integer("limit", default: 5) == 20)
        #expect(try arguments.integer("other", default: 5) == 5)
    }

    @Test
    func missingRequiredFlagIsUsageError() throws {
        let arguments = try Arguments(["asr"])
        #expect(throws: EvalError.self) { try arguments.required("model") }
    }

    @Test
    func flagWithoutValueIsUsageError() {
        #expect(throws: EvalError.self) { try Arguments(["asr", "--model"]) }
    }

    @Test
    func nonPositiveLimitIsRejected() throws {
        let arguments = try Arguments(["asr", "--limit", "0"])
        #expect(throws: EvalError.self) { try arguments.integer("limit", default: 5) }
    }
}
