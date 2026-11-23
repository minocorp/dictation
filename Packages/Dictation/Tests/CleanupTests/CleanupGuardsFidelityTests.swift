@testable import Cleanup
import Core
import Testing

internal struct CleanupGuardsFidelityTests {
    private let guards = CleanupGuards()

    private func failure(
        _ input: String,
        _ output: String,
        dictionary: [Word] = [],
    ) -> GuardFailure? {
        guards.verify(input: input, output: output, dictionary: dictionary)
    }

    @Test
    func spokenPunctuationWordsMayBeDropped() {
        #expect(failure("what is the plan question mark", "What is the plan?") == nil)
    }

    @Test
    func spokenCurrencyWordsMayBeDropped() {
        #expect(
            failure("it costs fifteen dollars and ninety nine cents", "It costs $15.99.") == nil
        )
    }

    @Test
    func singleItemListIsRejected() {
        #expect(
            failure("The deadline is March 3.", "1. The deadline is March 3.") == .structureLeak
        )
    }

    @Test
    func listItemsExcuseSpokenListNumbers() {
        #expect(
            failure(
                "준비물은 하나 여권 둘 지갑 셋 충전기",
                "준비물은:\n1. 여권\n2. 지갑\n3. 충전기",
            ) == nil
        )
    }

    @Test
    func listThatDropsItsLeadInIsRejected() {
        #expect(
            failure(
                "the rules are first be on time second be kind",
                "1. Be on time\n2. Be kind",
            ) == .droppedLeadIn
        )
        #expect(
            failure(
                "the rules are first be on time second be kind",
                "The rules are:\n1. Be on time\n2. Be kind",
            ) == nil
        )
    }

    @Test
    func dictionaryWordThatWasNotSpokenIsRejected() {
        let words = [Word(text: "Kubernetes", soundsLike: [], source: .manual)]
        let result = failure(
            "we deployed the new service to the cluster yesterday and it works fine",
            "We deployed the new service to the Kubernetes cluster yesterday and it works fine.",
            dictionary: words,
        )
        #expect(result == .novelWords, "\(String(describing: result))")
        #expect(
            failure("we use kubernetes daily", "We use Kubernetes daily.", dictionary: words)
                == nil
        )
    }

    @Test
    func soundAlikeReplacedBySpellingIsRetained() {
        let words = [Word(text: "Supabase", soundsLike: ["super base"], source: .manual)]
        let result = failure(
            "super base에서 row level security 정책을 추가해야 돼요",
            "Supabase에서 row level security 정책을 추가해야 돼요.",
            dictionary: words,
        )
        #expect(result == nil, "\(String(describing: result))")
    }
}
