public import Foundation

public struct DownloadSessionFactory: Sendable {
    private static let requestTimeout: TimeInterval = 60
    private static let resourceTimeout: TimeInterval = 7 * 24 * 60 * 60

    let makeConfiguration: @Sendable (_ allowsConstrainedNetwork: Bool) -> URLSessionConfiguration

    public init(
        makeConfiguration:
            @escaping @Sendable (_ allowsConstrainedNetwork: Bool) ->
            URLSessionConfiguration
    ) {
        self.makeConfiguration = makeConfiguration
    }

    public static let standard = DownloadSessionFactory { allowsConstrainedNetwork in
        let configuration = URLSessionConfiguration.default
        configuration.allowsConstrainedNetworkAccess = allowsConstrainedNetwork
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = resourceTimeout
        configuration.urlCache = nil
        return configuration
    }
}
