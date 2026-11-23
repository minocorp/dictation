@testable import Learning
import Testing

internal struct CorrectionDiffTests {
    private struct Case: Sendable {
        let name: String
        let inserted: String
        let baseline: String
        let final: String
        let expected: [Respelling]
    }

    private static let cases = [
        Case(
            name: "two words become one",
            inserted: "I use super base daily",
            baseline: "Notes: I use super base daily",
            final: "Notes: I use Supabase daily",
            expected: [Respelling(original: "super base", corrected: "Supabase")],
        ),
        Case(
            name: "case only is ignored for a proper noun too",
            inserted: "we deploy on vercel today",
            baseline: "we deploy on vercel today",
            final: "we deploy on Vercel today",
            expected: [],
        ),
        Case(
            name: "typo",
            inserted: "please recieve this",
            baseline: "please recieve this",
            final: "please receive this",
            expected: [Respelling(original: "recieve", corrected: "receive")],
        ),
        Case(
            name: "korean respelling keeps the particle",
            inserted: "슈퍼베이스를 씁니다",
            baseline: "슈퍼베이스를 씁니다",
            final: "수파베이스를 씁니다",
            expected: [Respelling(original: "슈퍼베이스를", corrected: "수파베이스를")],
        ),
        Case(
            name: "punctuation travels with the token",
            inserted: "Ask super base, then wait.",
            baseline: "Ask super base, then wait.",
            final: "Ask Supabase, then wait.",
            expected: [Respelling(original: "super base", corrected: "Supabase")],
        ),
        Case(
            name: "two separate respellings",
            inserted: "the versel and super base apps",
            baseline: "the versel and super base apps",
            final: "the Vercel and Supabase apps",
            expected: [
                Respelling(original: "versel", corrected: "Vercel"),
                Respelling(original: "super base", corrected: "Supabase"),
            ],
        ),
        Case(
            name: "joined text located with the first letter flipped",
            inserted: "Hello versel",
            baseline: "oh hello versel",
            final: "oh hello Vercel",
            expected: [Respelling(original: "versel", corrected: "Vercel")],
        ),
        Case(
            name: "unrelated rewrite is ignored",
            inserted: "I like cat food",
            baseline: "I like cat food",
            final: "I like dog food",
            expected: [],
        ),
        Case(
            name: "unrelated word is ignored",
            inserted: "it is completely done",
            baseline: "it is completely done",
            final: "it is supabase done",
            expected: [],
        ),
        Case(
            name: "punctuation only is ignored",
            inserted: "hello world",
            baseline: "hello world",
            final: "hello, world",
            expected: [],
        ),
        Case(
            name: "text typed after the insert is ignored",
            inserted: "hello world",
            baseline: "hello world",
            final: "hello world and more words",
            expected: [],
        ),
        Case(
            name: "deleted words are ignored",
            inserted: "hello big world",
            baseline: "hello big world",
            final: "hello world",
            expected: [],
        ),
        Case(
            name: "word split in two is ignored",
            inserted: "use supabase now",
            baseline: "use supabase now",
            final: "use super base now",
            expected: [],
        ),
        Case(
            name: "four words into one is ignored",
            inserted: "a b c d tail",
            baseline: "a b c d tail",
            final: "abcd tail",
            expected: [],
        ),
        Case(
            name: "edit outside the inserted text is ignored",
            inserted: "inserted words here",
            baseline: "Intro text. inserted words here",
            final: "Outro text. inserted words here",
            expected: [],
        ),
        Case(
            name: "case-only change is ignored",
            inserted: "buy iphone now",
            baseline: "buy iphone now",
            final: "buy iPhone now",
            expected: [],
        ),
        Case(
            name: "identical text",
            inserted: "same",
            baseline: "same",
            final: "same",
            expected: [],
        ),
        Case(
            name: "inserted text not found",
            inserted: "missing",
            baseline: "something else",
            final: "something other",
            expected: [],
        ),
    ]

    @Test(arguments: cases)
    private func findsRespellings(testCase: Case) {
        let found = CorrectionDiff.respellings(
            inserted: testCase.inserted,
            baseline: testCase.baseline,
            final: testCase.final,
        )
        #expect(found == testCase.expected, "\(testCase.name)")
    }

    @Test
    func aLargeDocumentWithALocalEditIsHandled() {
        let filler = Array(repeating: "lorem ipsum dolor sit amet", count: 2_000)
            .joined(separator: " ")
        let baseline = filler + " I use super base daily " + filler
        let final = filler + " I use Supabase daily " + filler
        let found = CorrectionDiff.respellings(
            inserted: "I use super base daily",
            baseline: baseline,
            final: final,
        )
        #expect(found == [Respelling(original: "super base", corrected: "Supabase")])
    }

    @Test
    func aHugeScatteredEditIsRejectedInsteadOfHanging() {
        let words = (0..<3_000).map { "word\($0)" }
        let baseline = words.joined(separator: " ")
        let final = words.reversed().joined(separator: " ")
        let found = CorrectionDiff.respellings(
            inserted: words[1_500],
            baseline: baseline,
            final: final,
        )
        #expect(found.isEmpty)
    }

    @Test
    func aClearedFieldDoesNotRetainTheBaseline() {
        #expect(!CorrectionDiff.retainsBaseline("I use super base daily", in: ""))
        #expect(!CorrectionDiff.retainsBaseline("I use super base daily", in: "ok thanks"))
        #expect(
            CorrectionDiff.retainsBaseline("I use super base daily", in: "I use Supabase daily")
        )
    }
}
