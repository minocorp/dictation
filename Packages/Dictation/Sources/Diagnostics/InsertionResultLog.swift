public import Core
public import Foundation
import Synchronization

public final class InsertionResultLog: Sendable {
    private let fileURL: URL
    private let counts: Mutex<[String: [String: Int]]>
    private let mirror = LogMirror()

    public init(fileURL: URL) {
        self.fileURL = fileURL
        let stored = (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([String: [String: Int]].self, from: $0) }
        counts = Mutex(stored ?? [:])
    }

    public func record(bundleID: String, outcome: InsertOutcome) {
        let snapshot = counts.withLock { counts in
            counts[bundleID, default: [:]][Self.label(of: outcome), default: 0] += 1
            return counts
        }
        persist(snapshot)
    }

    public func snapshot() -> [String: [String: Int]] {
        counts.withLock { $0 }
    }

    static func label(of outcome: InsertOutcome) -> String {
        switch outcome {
        case .inserted(let method): "inserted.\(method.rawValue)"
        case .copied(let reason): "copied.\(reason.rawValue)"
        case .refused(let reason): "refused.\(reason.rawValue)"
        }
    }

    private func persist(_ snapshot: [String: [String: Int]]) {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            try JSONEncoder().encode(snapshot).write(to: fileURL, options: .atomic)
        } catch {
            mirror.failure("insertion results write failed", code: (error as NSError).code)
        }
    }
}
