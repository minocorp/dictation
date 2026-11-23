import Core
import CryptoKit
import Foundation
import ModelCatalog
import Synchronization

internal struct DownloadFixtures: Sendable {
    static let constrainedHeader = "X-Constrained-Allowed"

    let directory = TestDirectory()
    let repo: String

    init(repo: String = "owner/\(UUID().uuidString)") {
        self.repo = repo
    }

    var storage: ModelStorage { ModelStorage(root: directory.url.appending(path: "Models")) }

    func makeEntry(
        files: [(path: String, data: Data)],
        corruptingDigestOf corrupted: String? = nil,
    )
        -> ModelEntry
    {
        let listing = files.map { file in
            ModelFile(
                path: file.path,
                bytes: file.data.count,
                sha256: file.path == corrupted
                    ? String(repeating: "0", count: 64) : digest(file.data),
            )
        }
        return ModelEntry(
            id: "test-model",
            stage: .speech,
            displayName: "Test",
            family: "test",
            repo: repo,
            revision: String(repeating: "a", count: 40),
            observedRevision: nil,
            format: .mlxSafetensors,
            quant: "4bit",
            license: "Apache-2.0",
            licenseVerified: true,
            languages: ["multilingual", "ko", "en"],
            minRAMGB: 8,
            downloadBytes: listing.reduce(0) { $0 + $1.bytes },
            files: listing,
            defaultFor: [],
            runtime: nil,
            verified: [],
            unverified: nil,
        )
    }

    func makeDownloader(
        availableBytes: Int? = .max,
        constrainedAccessAllowed: Bool = true,
    ) -> ModelDownloader {
        ModelDownloader(
            storage: storage,
            sessionFactory: DownloadSessionFactory { allowsConstrainedNetwork in
                let configuration = URLSessionConfiguration.ephemeral
                configuration.protocolClasses = [StubURLProtocol.self]
                configuration.allowsConstrainedNetworkAccess = allowsConstrainedNetwork
                configuration.httpAdditionalHeaders = [
                    Self.constrainedHeader: "\(allowsConstrainedNetwork)"
                ]
                return configuration
            },
            availableBytes: { availableBytes },
        )
    }

    func collect(_ stream: AsyncStream<DownloadEvent>) async -> [DownloadEvent] {
        var events: [DownloadEvent] = []
        for await event in stream {
            events.append(event)
        }
        return events
    }

    func payload(bytes: Int, seed: UInt8 = 7) -> Data {
        Data((0..<bytes).map { UInt8(truncatingIfNeeded: $0 &* 31 &+ Int(seed)) })
    }

    private func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
