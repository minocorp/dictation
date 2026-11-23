import Foundation

internal enum ReportFile {
    static func write(_ markdown: String, root: URL, now: Date = Date()) throws(EvalError) -> URL {
        let directory = root.appending(path: "run/eval")
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: now)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
            )
            var url = directory.appending(path: "\(stamp).md")
            var suffix = 2
            while FileManager.default.fileExists(atPath: url.path) {
                url = directory.appending(path: "\(stamp)-\(suffix).md")
                suffix += 1
            }
            try markdown.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            throw .download("cannot write report: \(error.localizedDescription)")
        }
    }
}
