internal import Foundation

internal struct AudioSetLoader {
    let root: URL
    let client: DatasetServerClient

    func clips(of set: AudioSet, limit: Int) async throws(EvalError) -> [AudioClip] {
        let directory = root.appending(path: "run/eval-data/\(set.rawValue)")
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
            )
        } catch {
            throw .download("cannot create \(directory.path)")
        }
        let total = try await client.total(of: set, cachedIn: directory)
        let stride = max(total / limit, 1)
        var clips: [AudioClip] = []
        for index in 0..<min(limit, total) {
            clips.append(
                try await client.clip(of: set, offset: index * stride, into: directory)
            )
        }
        return clips
    }
}
