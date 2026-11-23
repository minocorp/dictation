public import Core
public import Foundation
public import Observation

@MainActor
@Observable
public final class AboutModel {
    public enum Export: Equatable {
        case idle
        case ready(files: [String])
        case failed
    }

    public let version: String
    public private(set) var export = Export.idle
    public var isShowingLicenses = false

    @ObservationIgnored
    private let prepare: @Sendable () async throws(DiagnosticsError) -> DiagnosticsPackage
    @ObservationIgnored
    private let chooseDestination: @MainActor () -> URL?
    @ObservationIgnored
    private let modelEntries: @MainActor () -> [ModelEntry]
    @ObservationIgnored
    private var package: DiagnosticsPackage?

    public init(
        version: String,
        prepare: @escaping @Sendable () async throws(DiagnosticsError) -> DiagnosticsPackage,
        chooseDestination: @escaping @MainActor () -> URL?,
        modelEntries: @escaping @MainActor () -> [ModelEntry],
    ) {
        self.version = version
        self.prepare = prepare
        self.chooseDestination = chooseDestination
        self.modelEntries = modelEntries
    }

    var isShowingExport: Bool { export != .idle }

    var notices: [LicenseNotice] {
        let models = modelEntries().filter(\.isDownloadable)
            .map {
                LicenseNotice(name: $0.displayName, license: $0.license)
            }
        return LicenseNotice.thirdParty + models
    }

    public func beginExport() async {
        do {
            let prepared = try await prepare()
            package = prepared
            export = .ready(files: prepared.fileNames)
        } catch {
            package = nil
            export = .failed
        }
    }

    public func saveExport() {
        guard let package, let destination = chooseDestination() else { return }
        do {
            try package.write(destination)
            dismissExport()
        } catch {
            export = .failed
        }
    }

    public func dismissExport() {
        package = nil
        export = .idle
    }
}
