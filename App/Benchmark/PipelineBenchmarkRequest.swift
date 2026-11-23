#if DEBUG
import Foundation

internal struct PipelineBenchmarkRequest: Sendable {
    private static let audioFlag = "--benchmark-audio"
    private static let runsFlag = "--benchmark-runs"
    private static let gapFlag = "--benchmark-gap-seconds"
    private static let preheatFlag = "--benchmark-preheat-ms"
    private static let contextFlag = "--benchmark-context"

    let audioURLs: [URL]
    let runs: Int
    let contextBefore: String
    let preheat: Duration
    let gap: Duration

    static func fromArguments(_ arguments: [String] = CommandLine.arguments) -> Self? {
        guard let path = value(after: audioFlag, in: arguments) else { return nil }
        return Self(
            audioURLs: path.split(separator: ",").map { URL(fileURLWithPath: String($0)) },
            runs: value(after: runsFlag, in: arguments).flatMap { Int($0) } ?? 3,
            contextBefore: value(after: contextFlag, in: arguments) ?? "",
            preheat: .milliseconds(
                value(after: preheatFlag, in: arguments).flatMap { Int($0) } ?? 0
            ),
            gap: .seconds(value(after: gapFlag, in: arguments).flatMap { Int($0) } ?? 0),
        )
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }
}
#endif
