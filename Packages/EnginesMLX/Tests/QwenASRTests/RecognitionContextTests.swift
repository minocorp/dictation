@testable import QwenASR
import Testing

internal struct RecognitionContextTests {
    @Test
    func emptyContextStaysEmpty() {
        #expect(RecognitionContext.trimmed("  \n ") == "")
    }

    @Test
    func contextIsTrimmed() {
        #expect(RecognitionContext.trimmed("  Supabase, RLS \n") == "Supabase, RLS")
    }

    @Test
    func longContextKeepsItsEnd() {
        let long = String(repeating: "a", count: 300) + "tail"
        let trimmed = RecognitionContext.trimmed(long)
        #expect(trimmed.count == RecognitionContext.maximumCharacters)
        #expect(trimmed.hasSuffix("tail"))
    }
}
