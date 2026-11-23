import Foundation
@testable import ModelCatalog
import Testing

@Suite
internal struct DownloadSessionFactoryTests {
    @Test(arguments: [true, false])
    func standardSessionIsNotScheduledBySystemDaemon(allowsConstrainedNetwork: Bool) {
        let configuration = DownloadSessionFactory.standard.makeConfiguration(
            allowsConstrainedNetwork
        )
        #expect(configuration.identifier == nil)
        #expect(configuration.allowsConstrainedNetworkAccess == allowsConstrainedNetwork)
        #expect(!configuration.waitsForConnectivity)
    }
}
