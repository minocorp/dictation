internal struct Arguments {
    let command: String
    private let values: [String: String]

    init(_ raw: [String]) throws(EvalError) {
        guard let command = raw.first, !command.hasPrefix("--") else {
            throw .usage(Self.usage)
        }
        self.command = command
        var values: [String: String] = [:]
        var index = 1
        while index < raw.count {
            let flag = raw[index]
            guard flag.hasPrefix("--"), index + 1 < raw.count else { throw .usage(Self.usage) }
            values[String(flag.dropFirst(2))] = raw[index + 1]
            index += 2
        }
        self.values = values
    }

    static let usage = """
        eval asr --model <dir> --set fleurs-ko|fleurs-en|zeroth-ko|hike [--limit N] [--language auto|ko|en|ko,en] [--context <text>] [--trim-ms N]
        eval cleanup --model <dir|apple> [--set disfluent] [--fixtures <file>]
        """

    func value(for name: String) -> String? {
        values[name]
    }

    func required(_ name: String) throws(EvalError) -> String {
        guard let value = values[name] else { throw .usage("missing --\(name)\n\(Self.usage)") }
        return value
    }

    func integer(_ name: String, default fallback: Int) throws(EvalError) -> Int {
        guard let text = values[name] else { return fallback }
        guard let number = Int(text), number > 0 else { throw .usage("--\(name) must be positive") }
        return number
    }
}
