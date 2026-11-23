internal struct CueData: Sendable {
    let unambiguousFillers: LanguageCues
    let ambiguousFillers: LanguageCues
    let correctionCues: LanguageCues
    let repeatCue: String
    let ordinalListCues: LanguageCues
    let explicitListCues: LanguageCues
    let listMinDistinctOrdinals: Int
    let lineCommands: [String]
    let paragraphCommands: [String]
    let punctuationWords: [String]
    let numberWords: LanguageCues
    let questionCues: LanguageCues
    let properNounCues: [String]
    let stutterWords: Set<String>
    let letterNameAcronym: String
    let transliteratedNames: [String]
    let listCueWords: [String]
    let spokenSymbolWords: [String]
    let unspokenMarkers: Set<String>

    static let standard = CueData(
        unambiguousFillers: LanguageCues(
            en: ["um", "umm", "uh", "uhh", "uhm", "er", "erm", "hmm", "mm"],
            ko: ["음", "으음", "음음", "어", "어어", "어...", "아...", "으"],
        ),
        ambiguousFillers: LanguageCues(
            en: [
                "like", "you know", "i mean", "sort of", "kind of", "basically", "actually",
                "so yeah", "well",
            ],
            ko: ["그", "저", "저기", "막", "뭐", "뭐랄까", "그니까", "그러니까", "아"],
        ),
        correctionCues: LanguageCues(
            en: [
                "\\bscratch that\\b", "\\bstrike that\\b", "\\bdelete that\\b", "\\bnever ?mind\\b",
                "\\bno,? wait\\b", "\\bwait,? no\\b", "\\bno no\\b", "\\bi mean\\b",
                "\\bor rather\\b", "\\bmake that\\b", "\\blet me rephrase\\b", "\\bsorry,? \\w+",
                "(^|[.,?!] )no,? ", "\\bactually,? ",
            ],
            ko: [
                "(^|\\s)아니(\\s|,)", "그게 아니(라|고)", "\\S+ 말고 \\S+", "잠깐", "아 잠깐",
                "취소", "죄송", "정정", "다시 말(하면|해)", "아니 아니",
            ],
        ),
        repeatCue: "(^|\\s)(\\S{1,12})\\s+\\2(\\s|$)",
        ordinalListCues: LanguageCues(
            en: [
                "\\b(first|firstly|second|secondly|third|thirdly|finally)\\b",
                "\\b(number|step|item) (one|two|three|1|2|3)\\b",
            ],
            ko: ["첫째|둘째|셋째|넷째", "첫 ?번째|두 ?번째|세 ?번째", "하나는|둘은"],
        ),
        explicitListCues: LanguageCues(
            en: ["\\b(bullet|bullets|bulleted|numbered|list)\\b"],
            ko: ["다음과 같이", "목록|리스트|항목|번호"],
        ),
        listMinDistinctOrdinals: 2,
        lineCommands: ["new line", "newline", "next line", "줄 바꿔(줘)?", "줄 바꿈", "다음 줄"],
        paragraphCommands: [
            "new paragraph", "next paragraph", "문단 바꿔(줘)?", "새 문단", "단락 바꿔(줘)?",
        ],
        punctuationWords: [
            "comma", "period", "full stop", "question mark", "exclamation (mark|point)", "colon",
            "semicolon", "open paren", "close paren", "쉼표", "마침표", "물음표", "느낌표", "콜론",
        ],
        numberWords: LanguageCues(
            en: [
                "\\b(zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen"
                    + "|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty"
                    + "|fifty|sixty|seventy|eighty|ninety|hundred|thousand|million|billion|oh|first"
                    + "|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)\\b"
            ],
            ko: [
                "(?:(?:영|공|일|이|삼|사|오|육|칠|팔|구|십|백|천|만|억|한|두|세|네|둘|셋|넷|열)\\s?)+"
                    + "(?=원|시|분|초|일|월|년|개|명|번|대|층|살|주|달|퍼센트|프로|달러|엔|도|배|권|병|잔"
                    + "|마리|세|km|kg|cm|mm|m|g)",
                "하나|다섯|여섯|일곱|여덟|아홉|스물|스무|서른|마흔|쉰|예순|일흔|여든|아흔",
            ],
        ),
        questionCues: LanguageCues(
            en: [
                "^(what|who|whom|whose|where|when|why|how|which|is|are|am|was|were|do|does|did|can"
                    + "|could|will|would|should|shall|may|might|have|has|had)\\b"
            ],
            ko: [
                "뭐|뭔|무엇|무슨|어디|언제|누구|누가|왜|어떻게|어떤|어느|얼마|몇|어때|걸려",
                "(까|니|냐)$",
            ],
        ),
        properNounCues: [
            "\\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday|january|february|march"
                + "|april|june|july|august|september|october|november|december|i)\\b"
        ],
        stutterWords: [
            "i", "a", "the", "to", "and", "of", "it", "we", "is", "in", "on", "so", "but", "that",
        ],
        letterNameAcronym:
            "(?<![가-힣])(?=(?:에이|아이|이|오|유)*(?:비|씨|디|에프|지|에이치|제이|케이|엘|엠|엔|피|큐|알|에스|티|브이|더블유|엑스|와이|제트))"
            + "(?:에이|아이|이|오|유|비|씨|디|에프|지|에이치|제이|케이|엘|엠|엔|피|큐|알|에스|티|브이|더블유|엑스|와이|제트){2,}"
            + "(?:(?![가-힣])|(?=(?:에서|에|은|는|가|을|를|의|와|과|도|로|만|랑)(?![가-힣])))",
        transliteratedNames: [
            "깃허브", "깃랩", "파이썬", "클로드", "코덱스", "챗지피티", "수파베이스", "슈파베이스",
            "수퍼베이스", "도커", "쿠버네티스", "리눅스", "리액트", "앵귤러", "넥스트", "디스코드", "슬랙",
            "노션", "피그마", "엑스코드", "오픈에이아이", "앤트로픽", "버셀", "스트라이프", "포스트그레스",
            "레디스", "제미나이", "타입스크립트", "자바스크립트",
        ],
        listCueWords: [
            "first", "firstly", "second", "secondly", "third", "thirdly", "finally", "첫째", "둘째",
            "셋째", "넷째", "첫 번째", "두 번째", "세 번째",
        ],
        spokenSymbolWords: [
            "comma", "period", "full stop", "question mark", "exclamation mark",
            "exclamation point", "colon", "semicolon", "쉼표", "마침표", "물음표", "느낌표", "콜론",
            "dollars", "dollar", "cents", "cent", "euros", "euro", "달러", "센트",
        ],
        unspokenMarkers: ["am", "pm", "오전", "오후"],
    )
}
