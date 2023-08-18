import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgShareStoreMapTests: XCTestCase {
    private var data: ShareStoreMap!

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
        let share = try! await threshold.generate_new_share()
        data = share.shareStore
    }

    override func tearDown() {
        data = nil
    }

    func test_share_stores() {
        XCTAssertNotEqual(data.shareMaps.count, 0)
    }
}
