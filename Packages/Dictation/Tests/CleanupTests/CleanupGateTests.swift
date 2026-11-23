@testable import Cleanup
import Testing

internal struct CleanupGateTests {
    struct Case: Sendable {
        let text: String
        let contextBefore: String
        let expected: GateDecision

        init(_ text: String, _ expected: GateDecision, contextBefore: String = "") {
            self.text = text
            self.contextBefore = contextBefore
            self.expected = expected
        }
    }

    private let gate = CleanupGate(matcher: CueMatcher())

    static let koreanFalsePositives = [
        "그리고 내일 가요",
        "저녁에 먹어요",
        "막걸리 마셔요",
        "어제 다녀왔어요",
        "저희 팀이 해요",
        "아침에 일어났어요",
        "그래서 갔어요",
        "막내가 왔어요",
        "정말 아니야 괜찮아",
        "저건 아니라고 했어요",
        "그건 아니고 괜찮아요",
        "그게 아닌 것 같아요",
        "저건 아니까 괜찮아요",
        "그건 아니지 않아요",
        "그건 아니네 괜찮아요",
        "아니요 괜찮아요",
        "아니에요 괜찮아요",
        "저건 아니면 괜찮아요",
        "이거 주세요",
        "서울에서 만나요",
    ]
    .map { Case($0, .skipModel) }

    static let triggers = [
        Case("hello how are you", .skipModel),
        Case("뭐든 좋아요", .callModel),
        Case("어디서 만나요", .callModel),
        Case("파이썬이 뭐야", .callModel),
        Case("내일 부산 날씨가 어때", .callModel),
        Case("what is the capital of australia", .callModel),
        Case("can you send me the file", .callModel),
        Case("we wait until monday", .callModel),
        Case("super base에서 추가해요", .callModel),
        Case("hello\nworld", .callModel),
        Case("리액트 유즈 이펙트 알려줘", .callModel),
        Case("어제 피알 올렸어", .callModel),
        Case("에이피아이 키를 바꿨어", .callModel),
        Case("수파베이스 설정 끝냈어", .callModel),
        Case("컴퓨터가 느려요", .skipModel),
        Case("유즈 스테이트로 만들었어요", .callModel),
        Case("씨아이가 깨졌어요", .callModel),
        Case("버그 고쳤어요", .skipModel),
        Case("데이터가 많아요", .skipModel),
        Case("아이가 울어요", .skipModel),
        Case("we wait until later", .skipModel),
        Case("I like it", .callModel),
        Case("그 내일 가요", .callModel),
        Case("회의는 화요일 아니 목요일 해요", .callModel),
        Case("그건 아니, 목요일이야", .callModel),
        Case("아니 아니 그게 아니라 목요일", .callModel),
        Case("send it to Kim scratch that", .callModel),
        Case("tea or coffee coffee please", .callModel),
        Case("first install second run", .callModel),
        Case("first install", .callModel),
        Case("첫째로 해요", .skipModel),
        Case("첫째 둘째 해요", .callModel),
        Case("목록 보내줘", .callModel),
        Case("삼 시에 만나요", .callModel),
        Case("세 시에 만나요", .callModel),
        Case("5시에 만나요", .skipModel),
        Case("하나 주세요", .callModel),
        Case("three people", .callModel),
        Case("put a comma here", .callModel),
        Case("쉼표 찍어줘", .callModel),
        Case("one two three four five six seven eight nine ten eleven", .callModel),
        Case(String(repeating: "abcdefgh ", count: 9), .callModel),
        Case("see you there", .callModel, contextBefore: "intro\n1. apples\nand more"),
        Case("see you there", .callModel, contextBefore: "- milk\n- eggs"),
        Case("see you there", .skipModel, contextBefore: "a - b"),
    ]

    @Test(arguments: koreanFalsePositives + triggers)
    func decides(_ example: Case) {
        #expect(
            gate.decision(forRuleText: example.text, contextBefore: example.contextBefore)
                == example.expected,
            "\(example.text)",
        )
    }
}
