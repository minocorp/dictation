@testable import Cleanup
import Core
import Testing

internal struct CleanupRulesTests {
    struct Case: Sendable {
        let input: String
        let expected: String
    }

    private let rules = CleanupRules()

    static let sanitizing = [
        Case(input: "  hello\t\t world  ", expected: "hello world"),
        Case(input: "a <|im_start|>b<|im_end|> c", expected: "a b c"),
        Case(input: "e\u{301}", expected: "\u{E9}"),
    ]

    static let spokenFormat = [
        Case(input: "안녕하세요 줄 바꿔 회의 자료", expected: "안녕하세요\n회의 자료"),
        Case(input: "안녕하세요 줄 바꿔줘 회의", expected: "안녕하세요\n회의"),
        Case(input: "hello new line world", expected: "hello\nworld"),
        Case(input: "hello, new paragraph, world", expected: "hello\n\nworld"),
        Case(input: "인사 문단 바꿔 본문", expected: "인사\n\n본문"),
        Case(input: "new line", expected: "new line"),
        Case(input: "줄 바꿔", expected: "줄 바꿔"),
        Case(input: "a newlines b", expected: "a newlines b"),
        Case(input: "put a comma here", expected: "put a comma here"),
    ]

    static let fillers = [
        Case(input: "um hello er world", expected: "hello world"),
        Case(input: "Well, um, okay", expected: "Well, okay"),
        Case(input: "음 어 안녕", expected: "안녕"),
        Case(input: "음... 안녕 으", expected: "안녕"),
        Case(input: "hmm. yes", expected: "yes"),
        Case(input: "like hello", expected: "like hello"),
        Case(input: "어... 그래", expected: "그래"),
    ]

    static let stutters = [
        Case(input: "the the cat", expected: "the cat"),
        Case(input: "I I think so", expected: "I think so"),
        Case(input: "That that is it", expected: "that is it"),
        Case(input: "정말 정말 좋아", expected: "정말 정말 좋아"),
        Case(input: "very very good", expected: "very very good"),
        Case(input: "no no stop", expected: "no no stop"),
        Case(input: "go go go", expected: "go go go"),
        Case(input: "이 이 사람", expected: "이 사람"),
        Case(input: "room 1 1 floor", expected: "room 1 1 floor"),
        Case(input: "7 7 7", expected: "7 7 7"),
    ]

    @Test(arguments: sanitizing)
    func sanitizes(_ example: Case) {
        #expect(rules.sanitized(example.input) == example.expected)
    }

    @Test(arguments: spokenFormat)
    func appliesSpokenFormat(_ example: Case) {
        #expect(rules.ruleCleaned(example.input) == example.expected)
    }

    @Test(arguments: fillers)
    func removesUnambiguousFillers(_ example: Case) {
        #expect(rules.ruleCleaned(example.input) == example.expected)
    }

    static let koreanNumbers = [
        Case(input: "삼만 오천 원이고 이십삼 일", expected: "35,000원이고 23일"),
        Case(input: "오후 네 시 이십 분에", expected: "오후 4시 20분에"),
        Case(input: "오전 아홉 시 반에", expected: "오전 9시 반에"),
        Case(input: "택배비는 이천오백 원이고", expected: "택배비는 2,500원이고"),
        Case(input: "총 이십이 명이에요", expected: "총 22명이에요"),
        Case(input: "이천이십육 년 삼 월", expected: "2026년 3월"),
        Case(input: "백칠십오 센티예요", expected: "175센티예요"),
        Case(input: "스물다섯 살이고", expected: "25살이고"),
        Case(input: "커피 한 잔 주세요", expected: "커피 한 잔 주세요"),
        Case(input: "두 번 실행돼요", expected: "두 번 실행돼요"),
        Case(input: "이 일 때문에", expected: "이 일 때문에"),
        Case(input: "하나 여권 둘 지갑", expected: "하나 여권 둘 지갑"),
        Case(input: "두 번째 순서", expected: "두 번째 순서"),
    ]

    @Test(arguments: koreanNumbers)
    func writesKoreanNumbersAsDigits(_ example: Case) {
        #expect(rules.writingKoreanNumbers(example.input) == example.expected)
    }

    @Test
    func fillerFreeKeepsSpokenFormatCommandsForTheModel() {
        #expect(rules.fillerFree("음 hello new line the the world") == "hello new line the world")
    }

    @Test(arguments: stutters)
    func collapsesShortRepeats(_ example: Case) {
        #expect(rules.ruleCleaned(example.input) == example.expected)
    }

    struct CasingCase: Sendable {
        let input: String
        let isFinal: Bool
        let expected: String
    }

    static let casing = [
        CasingCase(input: "hello world", isFinal: true, expected: "Hello world."),
        CasingCase(input: "hello world", isFinal: false, expected: "Hello world"),
        CasingCase(input: "see src/app.ts now", isFinal: true, expected: "See src/app.ts now."),
        CasingCase(
            input: "useEffect runs twice",
            isFinal: true,
            expected: "useEffect runs twice.",
        ),
        CasingCase(input: "one. two? three", isFinal: false, expected: "One. Two? Three"),
        CasingCase(input: "hello", isFinal: true, expected: "Hello"),
        CasingCase(input: "is it ready?", isFinal: true, expected: "Is it ready?"),
        CasingCase(input: "안녕하세요 반갑습니다", isFinal: true, expected: "안녕하세요 반갑습니다."),
        CasingCase(input: "yes\nno way", isFinal: true, expected: "Yes\nNo way."),
        CasingCase(input: "item\n1.", isFinal: true, expected: "Item\n1."),
        CasingCase(
            input: "i think a.b is fine. e.g",
            isFinal: false,
            expected: "I think a.b is fine. e.g",
        ),
        CasingCase(input: "x is an @mention ok", isFinal: false, expected: "X is an @mention ok"),
    ]

    @Test(arguments: casing)
    func capitalizesAndEnds(_ example: CasingCase) {
        #expect(
            rules.finished(example.input, isFinalSegment: example.isFinal, dictionary: [])
                == example.expected
        )
    }

    static let newlines = [
        Case(input: "a \n b", expected: "a\nb"),
        Case(input: "a\n\n\n\nb", expected: "a\n\nb"),
        Case(input: "a  \n\n  b", expected: "a\n\nb"),
    ]

    @Test(arguments: newlines)
    func tidiesNewlines(_ example: Case) {
        #expect(rules.tidyingNewlines(example.input) == example.expected)
    }

    private let dictionary = [
        Word(text: "Supabase", soundsLike: ["super base", "supa base"], source: .manual),
        Word(text: "minodevss", soundsLike: ["mino dev ss"], source: .learned),
        Word(text: "useEffect", soundsLike: [], source: .manual),
    ]

    static let dictionaryCases = [
        Case(input: "use super base now", expected: "use Supabase now"),
        Case(input: "use Super   Base now", expected: "use Supabase now"),
        Case(input: "supa base and super base", expected: "Supabase and Supabase"),
        Case(input: "super basement", expected: "super basement"),
        Case(input: "superbase", expected: "superbase"),
        Case(input: "push to mino dev ss.", expected: "push to minodevss."),
        Case(input: "use effect", expected: "use effect"),
    ]

    @Test(arguments: dictionaryCases)
    func replacesSoundAlikes(_ example: Case) {
        #expect(
            rules.applyingDictionary(example.input, dictionary: dictionary) == example.expected
        )
    }

    @Test
    func dictionaryRunsOnFinishedText() {
        let finished = rules.finished(
            "use super base",
            isFinalSegment: true,
            dictionary: dictionary,
        )
        #expect(finished == "Use Supabase.")
    }

    @Test
    func koreanSoundAlikeReplacedBeforeParticle() {
        let words = [Word(text: "Vercel", soundsLike: ["버셀"], source: .manual)]
        #expect(
            rules.applyingDictionary("버셀에 배포해요", dictionary: words) == "Vercel에 배포해요"
        )
    }

    @Test
    func particlesAttachToALatinWord() {
        #expect(
            rules.joiningParticles("GitHub 에서 Claude Code 로 PR 을 올려요")
                == "GitHub에서 Claude Code로 PR을 올려요"
        )
        #expect(rules.joiningParticles("version 2 이상 지원") == "version 2 이상 지원")
        #expect(rules.joiningParticles("use React 로직") == "use React 로직")
    }
}
