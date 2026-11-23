public import Foundation
import Synchronization

public final class DiagnosticsLog: Sendable {
    public static let defaultMaxBytes = 512 * 1_024

    private static let fileName = "diagnostics.log"
    private static let previousFileName = "diagnostics.1.log"

    private let directory: URL
    private let maxBytes: Int
    private let now: @Sendable () -> Date
    private let writeLock = Mutex(())
    private let mirror = LogMirror()

    private var currentFile: URL { directory.appending(path: Self.fileName) }
    private var previousFile: URL { directory.appending(path: Self.previousFileName) }

    public init(directory: URL, maxBytes: Int, now: @escaping @Sendable () -> Date) {
        self.directory = directory
        self.maxBytes = maxBytes
        self.now = now
    }

    public func debug(_ category: String, _ message: String) {
        log(.debug, category, message)
    }

    public func info(_ category: String, _ message: String) {
        log(.info, category, message)
    }

    public func error(_ category: String, _ message: String) {
        log(.error, category, message)
    }

    public func log(_ level: LogLevel, _ category: String, _ message: String) {
        mirror.write(level, category, message)
        let line = Self.line(at: now(), level, category, message)
        writeLock.withLock { _ in append(line) }
    }

    public func recentLog() -> Data {
        writeLock.withLock { _ in
            let older = (try? Data(contentsOf: previousFile)) ?? Data()
            let newer = (try? Data(contentsOf: currentFile)) ?? Data()
            return Data((older + newer).suffix(maxBytes))
        }
    }

    private static func line(
        at date: Date,
        _ level: LogLevel,
        _ category: String,
        _ message: String,
    ) -> Data {
        let flattened = message.replacing(/\s*[\r\n]+\s*/, with: " ")
        let stamp = date.formatted(.iso8601)
        return Data("\(stamp) \(level.rawValue) \(category) \(flattened)\n".utf8)
    }

    private func append(_ line: Data) {
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
            )
            if !FileManager.default.fileExists(atPath: currentFile.path(percentEncoded: false)) {
                try Data().write(to: currentFile)
            }
            let handle = try FileHandle(forWritingTo: currentFile)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
            if try handle.offset() >= UInt64(maxBytes) { try rotate() }
        } catch {
            mirror.failure("log write failed", code: (error as NSError).code)
        }
    }

    private func rotate() throws {
        try? FileManager.default.removeItem(at: previousFile)
        try FileManager.default.moveItem(at: currentFile, to: previousFile)
    }
}
