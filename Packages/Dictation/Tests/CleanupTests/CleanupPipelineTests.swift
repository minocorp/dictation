@testable import Cleanup
import Clocks
import Core
import CoreTesting
import Foundation
import Testing

internal struct CleanupPipelineTests {
    struct WordCounter: TokenCounting {
        func tokenCount(of text: String) -> Int {
            text.split(whereSeparator: \.isWhitespace).count
        }
    }

    private static let korean = "음 어 그 저기 내일 회의가 막 세 시에 있거든요"
    private static let koreanCleaned = "내일 회의가 3시에 있거든요."

    private let engine = FakeCleanupEngine()

    private func pipeline(
        engine: any CleanupEngine,
        budget: CleanupBudget = .recommended(for: .ram16),
        chunkLimit: Int = 250,
    ) -> CleanupPipeline<CoreTesting.TestClock> {
        CleanupPipeline(
            engine: engine,
            clock: CoreTesting.TestClock(),
            budget: budget,
            chunker: TextChunker(counter: WordCounter(), maximumTokens: chunkLimit),
        )
    }

    private func context(
        dictionary: [Word] = [],
        contextBefore: String = "",
        isFinalSegment: Bool = true,
    ) -> CleanupContext {
        CleanupContext(
            dictionary: dictionary,
            contextBefore: contextBefore,
            isFinalSegment: isFinalSegment,
        )
    }

    private func preferences(cleanup: Bool = true) -> Preferences {
        var preferences = Preferences.makeDefault(
            globeSwitchesInputSource: false,
            preferredLanguages: [Locale(identifier: "ko-KR")],
        )
        preferences.cleanup = cleanup
        return preferences
    }

    @Test
    func cleanupOffRunsOnlySanitize() async throws {
        let result = try await pipeline(engine: engine)
            .clean(
                "  um  hello <|x|>world  ",
                context: context(),
                preferences: preferences(cleanup: false),
            )
        #expect(result == CleanupResult(text: "um hello world", source: .disabled))
        #expect(engine.cleanRequests.isEmpty)
    }

    @Test
    func gateSkipUsesRulesWithoutEngine() async throws {
        let dictionary = [Word(text: "Supabase", soundsLike: ["super base"], source: .manual)]
        let result = try await pipeline(engine: engine)
            .clean(
                "um use super base",
                context: context(dictionary: dictionary),
                preferences: preferences(),
            )
        #expect(result == CleanupResult(text: "Use Supabase.", source: .gateSkipped))
        #expect(engine.cleanRequests.isEmpty)
    }

    @Test
    func acceptedModelOutputIsReturned() async throws {
        engine.cleanResult = .success(Self.koreanCleaned)
        let words = [Word(text: "Supabase", soundsLike: [], source: .manual)]
        let result = try await pipeline(engine: engine)
            .clean(
                Self.korean,
                context: context(dictionary: words, contextBefore: "앞 문장"),
                preferences: preferences(),
            )
        #expect(result == CleanupResult(text: Self.koreanCleaned, source: .model))
        let request = try #require(engine.cleanRequests.first)
        #expect(request.text == "그 저기 내일 회의가 막 3시에 있거든요")
        #expect(request.dictionary == words)
        #expect(request.contextBefore == "앞 문장")
        #expect(request.languages == preferences().languages)
    }

    @Test
    func modelOutputGetsDictionaryReplacements() async throws {
        engine.cleanResult = .success("내일 super base 회의가 3시에 있거든요.")
        let words = [Word(text: "Supabase", soundsLike: ["super base"], source: .manual)]
        let result = try await pipeline(engine: engine)
            .clean(
                "음 어 그 저기 내일 super base 회의가 막 세 시에 있거든요",
                context: context(dictionary: words),
                preferences: preferences(),
            )
        #expect(result.text == "내일 Supabase 회의가 3시에 있거든요.")
        #expect(result.source == .model)
    }

    @Test
    func guardFailureFallsBackToRuleText() async throws {
        engine.cleanResult = .success("약 2시간 30분 걸립니다.")
        let result = try await pipeline(engine: engine)
            .clean(
                "서울에서 부산까지 KTX로 얼마나 걸려 그",
                context: context(),
                preferences: preferences(),
            )
        #expect(result.text == "서울에서 부산까지 KTX로 얼마나 걸려 그.")
        guard case .fallback(.guardFailed) = result.source else {
            Issue.record("expected guard fallback, got \(result.source)")
            return
        }
    }

    @Test
    func engineErrorFallsBackToRuleText() async throws {
        engine.cleanResult = .failure(.modelUnavailable)
        let result = try await pipeline(engine: engine)
            .clean(
                Self.korean,
                context: context(),
                preferences: preferences(),
            )
        #expect(result.text == "그 저기 내일 회의가 막 3시에 있거든요.")
        #expect(result.source == .fallback(.engine(.modelUnavailable)))
    }

    @Test
    func cancelledEngineThrowsCancelled() async {
        engine.cleanResult = .failure(.cancelled)
        await #expect(throws: CleanupError.cancelled) {
            try await pipeline(engine: engine)
                .clean(
                    Self.korean,
                    context: context(),
                    preferences: preferences(),
                )
        }
    }

    @Test
    func timeoutFallsBackToRuleText() async throws {
        let pipeline = CleanupPipeline(
            engine: HangingCleanupEngine(),
            clock: ImmediateClock<Duration>(),
            budget: .recommended(for: .ram16),
        )
        let result = try await pipeline.clean(
            Self.korean,
            context: context(isFinalSegment: false),
            preferences: preferences(),
        )
        #expect(result.text == "그 저기 내일 회의가 막 3시에 있거든요")
        #expect(result.source == .fallback(.timedOut))
    }

    @Test
    func longInputIsCleanedInChunksWithEarlierChunksAsContext() async throws {
        engine.cleanResult = .success("Hello there.")
        let result = try await pipeline(engine: engine, chunkLimit: 3)
            .clean(
                "like hello there. like hello there.",
                context: context(contextBefore: "Intro"),
                preferences: preferences(),
            )
        #expect(result == CleanupResult(text: "Hello there. Hello there.", source: .model))
        #expect(engine.cleanRequests.map(\.text) == ["like hello there.", "like hello there."])
        #expect(engine.cleanRequests.map(\.contextBefore) == ["Intro", "Intro Hello there."])
    }

    @Test
    func laterChunkGuardFailureFallsBackForTheWholeSegment() async throws {
        engine.cleanResult = .success("Totally different words appear here now.")
        let result = try await pipeline(engine: engine, chunkLimit: 3)
            .clean(
                "like hello there. like hello there.",
                context: context(),
                preferences: preferences(),
            )
        #expect(result.text == "Like hello there. Like hello there.")
        guard case .fallback(.guardFailed) = result.source else {
            Issue.record("expected guard fallback, got \(result.source)")
            return
        }
    }
}
