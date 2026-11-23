internal import Core
internal import Foundation

internal struct CleanupCase: Decodable {
    struct Entry: Decodable {
        let text: String
        let soundsLike: [String]
    }

    let id: String
    let category: String
    let input: String
    let expected: String
    let dictionary: [Entry]
    let contextBefore: String

    var words: [Word] {
        dictionary.map { Word(text: $0.text, soundsLike: $0.soundsLike, source: .manual) }
    }

    var isNoOp: Bool { input == expected }

    var mustStayContent: Bool { category == "question-stay" || category == "injection-stay" }

    static func load(from file: URL) throws(EvalError) -> [CleanupCase] {
        let text: String
        do {
            text = try String(contentsOf: file, encoding: .utf8)
        } catch {
            throw .fixtures("cannot read \(file.path)")
        }
        let decoder = JSONDecoder()
        var cases: [CleanupCase] = []
        for line in text.split(separator: "\n") where !line.isEmpty {
            do {
                cases.append(try decoder.decode(CleanupCase.self, from: Data(line.utf8)))
            } catch {
                throw .fixtures("bad fixture line: \(line.prefix(60))")
            }
        }
        return cases
    }
}
