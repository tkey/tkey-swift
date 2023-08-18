import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgShareStorePolyIdIndexMapTests: XCTestCase {
    private var data: ShareStorePolyIdIndexMap!

    override func setUp() async throws {
        let postboxKey = try! PrivateKey.generate()
        let storageLayer = try! StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2)
        let serviceProvider = try! ServiceProvider(enableLogging: true, postboxKey: postboxKey.hex)
        let threshold = try! ThresholdKey(
            storageLayer: storageLayer,
            serviceProvider: serviceProvider,
            enableLogging: true,
            manualSync: false
        )

        _ = try! await threshold.initialize()
        _ = try! await threshold.reconstruct()
        data = try! threshold.get_shares()
    }

    override func tearDown() {
        data = nil
    }

    func test_share_stores() {
        XCTAssertNotEqual(data.shareMaps.count, 0)
    }
}
