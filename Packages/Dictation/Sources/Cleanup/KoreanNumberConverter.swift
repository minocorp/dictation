internal struct KoreanNumberConverter: Sendable {
    private enum Step {
        case proceed
        case finish
        case reject
    }

    private struct Piece {
        let head: String
        let tail: String

        init(_ token: String) {
            let leading = token.prefix { $0.unicodeScalars.allSatisfy(\.isHangul) }
            head = String(leading)
            tail = String(token.dropFirst(leading.count))
        }
    }

    private struct Split {
        let numeral: KoreanNumeral
        let rest: String
    }

    private struct Run {
        var parts: [KoreanNumeral] = []
        var suffix = ""
        var counter: String?
        var consumed = 0

        var joinedSource: String { parts.map(\.source).joined() }
    }

    func convert(_ tokens: [String]) -> [String] {
        var output: [String] = []
        var index = 0
        while index < tokens.count {
            guard let run = run(at: index, in: tokens), let replacement = replacement(for: run)
            else {
                output.append(tokens[index])
                index += 1
                continue
            }
            output.append(contentsOf: replacement)
            index += run.consumed
        }
        return output
    }

    func formatted(_ tokens: [String]) -> [String] {
        var output: [String] = []
        var index = 0
        while index < tokens.count {
            guard let run = run(at: index, in: tokens), let written = written(run) else {
                output.append(tokens[index])
                index += 1
                continue
            }
            output.append(written)
            index += run.consumed
        }
        return output
    }

    private static let ambiguousSyllables: Set<String> = ["이", "일", "구", "공", "오", "팔", "사"]
    private static let sureCounters: Set<String> = ["시", "분", "초", "원", "월", "년", "퍼센트", "달러"]
    private static let nativeCounters: Set<String> = ["시", "살"]
    private static let ungroupedCounters: Set<String> = ["년", "월", "일", "시", "분", "초"]
    private static let groupingMinimum = 1000

    private func written(_ run: Run) -> String? {
        guard let counter = run.counter, !run.suffix.isEmpty,
            let numeral = KoreanNumeral.parse(run.joinedSource), replacement(for: run) != nil
        else { return nil }
        if numeral.isNative {
            guard Self.nativeCounters.contains(counter) || (Int(numeral.digits) ?? 0) >= 20 else {
                return nil
            }
        } else if run.parts.count == 1, Self.ambiguousSyllables.contains(run.joinedSource),
            !Self.sureCounters.contains(counter)
        {
            return nil
        }
        return grouped(numeral.digits, counter: counter) + run.suffix
    }

    private func grouped(_ digits: String, counter: String) -> String {
        guard let value = Int(digits), value >= Self.groupingMinimum,
            !Self.ungroupedCounters.contains(counter), digits.first != "0"
        else { return digits }
        var groups: [String] = []
        var rest = Substring(digits)
        while rest.count > 3 {
            groups.insert(String(rest.suffix(3)), at: 0)
            rest = rest.dropLast(3)
        }
        groups.insert(String(rest), at: 0)
        return groups.joined(separator: ",")
    }

    private func replacement(for run: Run) -> [String]? {
        guard let joined = KoreanNumeral.parse(run.joinedSource) else { return nil }
        if let counter = run.counter {
            let isOrdinal = counter == "번" && run.suffix.dropFirst(counter.count).hasPrefix("째")
            guard !isOrdinal else { return nil }
        } else if joined.syllableCount < 2 || (run.parts.count > 1 && joined.isDigitSequence) {
            return nil
        }
        return [joined.digits] + (run.suffix.isEmpty ? [] : [run.suffix])
    }

    private func run(at start: Int, in tokens: [String]) -> Run? {
        var run = Run()
        var cursor = start
        scan: while cursor < tokens.count {
            let next = cursor + 1 < tokens.count ? tokens[cursor + 1] : nil
            switch step(token: tokens[cursor], next: next, run: &run) {
            case .proceed:
                cursor += 1
            case .finish:
                cursor += 1
                break scan
            case .reject:
                break scan
            }
        }
        run.consumed = cursor - start
        return run.parts.isEmpty ? nil : run
    }

    private func step(token: String, next: String?, run: inout Run) -> Step {
        let piece = Piece(token)
        if !run.parts.isEmpty, isCounterToken(piece, next: next, run: run) {
            return endWithCounter(token, run: &run)
        }
        if let split = split(piece.head) {
            return take(split, tail: piece.tail, into: &run)
        }
        if !run.parts.isEmpty, KoreanCounters.leading(in: piece.head) != nil {
            return endWithCounter(token, run: &run)
        }
        return .reject
    }

    private func endWithCounter(_ token: String, run: inout Run) -> Step {
        run.counter = KoreanCounters.leading(in: token)
        run.suffix = token
        return .finish
    }

    private func isCounterToken(_ piece: Piece, next: String?, run: Run) -> Bool {
        guard KoreanCounters.isCounter(piece.head) else { return false }
        guard let numeral = KoreanNumeral.parse(piece.head) else { return true }
        let continuesRun =
            KoreanNumeral.parse(run.joinedSource + numeral.source) != nil
            && next.map { KoreanCounters.leading(in: Piece($0).head) != nil } == true
        return !continuesRun
    }

    private func take(_ split: Split, tail: String, into run: inout Run) -> Step {
        run.parts.append(split.numeral)
        guard split.rest.isEmpty else {
            run.counter = KoreanCounters.leading(in: split.rest)
            run.suffix = split.rest + tail
            return .finish
        }
        run.suffix = tail
        return tail.isEmpty ? .proceed : .finish
    }

    private func split(_ head: String) -> Split? {
        let characters = Array(head)
        for length in stride(from: characters.count, through: 1, by: -1) {
            let rest = String(characters[length...])
            guard let numeral = KoreanNumeral.parse(String(characters[..<length])) else { continue }
            if rest.isEmpty || KoreanCounters.leading(in: rest) != nil {
                return Split(numeral: numeral, rest: rest)
            }
        }
        return nativeSplit(characters)
    }

    private func nativeSplit(_ characters: [Character]) -> Split? {
        for length in stride(from: characters.count, through: 2, by: -1) {
            let rest = String(characters[length...])
            guard !rest.hasPrefix("째"),
                let numeral = KoreanNumeral.parse(String(characters[..<length])), numeral.isNative
            else { continue }
            return Split(numeral: numeral, rest: rest)
        }
        return nil
    }
}
