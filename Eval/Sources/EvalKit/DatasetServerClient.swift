internal import Foundation

internal struct DatasetServerClient {
    private static let rowsEndpoint = "https://datasets-server.huggingface.co/rows"
    private static let attempts = 4

    let session: URLSession

    func total(of set: AudioSet, cachedIn directory: URL) async throws(EvalError) -> Int {
        let file = directory.appending(path: "\(set.rawValue).total")
        if let text = try? String(contentsOf: file, encoding: .utf8),
            let total = Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
        {
            return total
        }
        let total = try await page(of: set, offset: 0).total
        try? String(total).write(to: file, atomically: true, encoding: .utf8)
        return total
    }

    func clip(
        of set: AudioSet,
        offset: Int,
        into directory: URL,
    ) async throws(EvalError)
        -> AudioClip
    {
        let stem = "\(set.rawValue)-\(offset)"
        let referenceFile = directory.appending(path: "\(stem).txt")
        if let reference = try? String(contentsOf: referenceFile, encoding: .utf8),
            let audio = try? FileManager.default
                .contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: nil,
                )
                .first(where: {
                    $0.deletingPathExtension().lastPathComponent == stem
                        && $0.pathExtension != "txt"
                })
        {
            return AudioClip(id: stem, file: audio, reference: reference)
        }
        let page = try await page(of: set, offset: offset)
        guard let entry = page.rows.first,
            case .audio(let source) = entry.row["audio"],
            case .text(let reference) = entry.row[set.referenceField]
        else { throw .download("\(set.rawValue) row \(offset) has no audio or reference") }
        let file = directory.appending(path: "\(set.rawValue)-\(offset).\(extensionOf(source))")
        if !FileManager.default.fileExists(atPath: file.path) {
            try await save(source, to: file)
        }
        try? reference.write(to: referenceFile, atomically: true, encoding: .utf8)
        return AudioClip(id: "\(set.rawValue)-\(offset)", file: file, reference: reference)
    }

    private func page(of set: AudioSet, offset: Int) async throws(EvalError) -> DatasetPage {
        var components = URLComponents(string: Self.rowsEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "dataset", value: set.dataset),
            URLQueryItem(name: "config", value: set.configuration),
            URLQueryItem(name: "split", value: "test"),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "length", value: "1"),
        ]
        guard let url = components?.url else { throw .download("bad dataset url") }
        let data = try await fetch(url)
        do {
            return try JSONDecoder().decode(DatasetPage.self, from: data)
        } catch {
            throw .download("cannot decode \(set.rawValue) page: \(error.localizedDescription)")
        }
    }

    private func save(_ source: URL, to file: URL) async throws(EvalError) {
        let data = try await fetch(source)
        do {
            try data.write(to: file)
        } catch {
            throw .download("cannot save \(file.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private func fetch(_ url: URL) async throws(EvalError) -> Data {
        var lastFailure = "no attempt"
        for attempt in 1...Self.attempts {
            do {
                let (data, response) = try await session.data(from: url)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if status == 200 { return data }
                lastFailure = "HTTP \(status)"
            } catch {
                lastFailure = error.localizedDescription
            }
            try? await Task.sleep(for: .seconds(attempt * 2))
        }
        throw .download("\(url.host() ?? "host") \(lastFailure)")
    }

    private func extensionOf(_ source: URL) -> String {
        source.pathExtension.isEmpty ? "wav" : source.pathExtension
    }
}
