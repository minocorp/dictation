public import Core
import Synchronization

public final class FakeWordStore: WordStore {
    private struct State {
        var words: [String: Word] = [:]
        var correctionCounts: [String: Int] = [:]
        var failure: StoreError?
    }

    private static let promotionThreshold = 2

    private let state = Mutex(State())

    public var failure: StoreError? {
        get { state.withLock { $0.failure } }
        set { state.withLock { $0.failure = newValue } }
    }

    public var words: [Word] {
        state.withLock { $0.words.values.sorted { $0.text < $1.text } }
    }

    public init() {}

    public func all() async throws(StoreError) -> [Word] {
        try run { .success($0.words.values.sorted { $0.text < $1.text }) }
    }

    public func add(_ word: Word) async throws(StoreError) {
        try run { state in
            state.words[word.text] = word
            return .success(())
        }
    }

    public func remove(text: String) async throws(StoreError) {
        try run { state in
            state.words[text] = nil
            return .success(())
        }
    }

    public func recordCorrection(
        from original: String,
        to corrected: String,
    ) async throws(StoreError) -> Word? {
        try run { state in
            let key = "\(original)\u{0}\(corrected)"
            let count = state.correctionCounts[key, default: 0] + 1
            state.correctionCounts[key] = count
            guard count >= Self.promotionThreshold, state.words[corrected] == nil else {
                return .success(nil)
            }
            let word = Word(text: corrected, soundsLike: [original], source: .learned)
            state.words[corrected] = word
            return .success(word)
        }
    }

    private func run<T>(_ body: (inout State) -> Result<T, StoreError>) throws(StoreError) -> T {
        let result = state.withLock { state -> Result<T, StoreError> in
            if let failure = state.failure { return .failure(failure) }
            return body(&state)
        }
        return try result.get()
    }
}
