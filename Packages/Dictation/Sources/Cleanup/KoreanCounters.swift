internal enum KoreanCounters {
    static let all = [
        "센티미터", "센티", "미터", "킬로그램", "킬로", "그램", "리터",
        "퍼센트", "달러", "마리", "프로", "원", "시", "분", "초", "일", "월", "년", "개", "명", "번",
        "대", "층", "살", "주", "달", "도", "배", "권", "병", "잔", "세",
    ]

    static func leading(in text: String) -> String? {
        all.first { text.hasPrefix($0) }
    }

    static func isCounter(_ text: String) -> Bool {
        all.contains(text)
    }
}
