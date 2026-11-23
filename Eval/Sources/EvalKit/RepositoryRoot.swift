import Foundation

internal enum RepositoryRoot {
    static func find(
        from start: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    )
        -> URL
    {
        var directory = start
        while directory.path != "/" {
            if FileManager.default.fileExists(atPath: directory.appending(path: "AGENTS.md").path) {
                return directory
            }
            directory = directory.deletingLastPathComponent()
        }
        return start
    }
}
