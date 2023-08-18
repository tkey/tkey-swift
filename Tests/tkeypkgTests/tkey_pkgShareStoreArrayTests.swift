import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgShareStoreArrayTests: XCTestCase {
    private var data: ShareStoreArray!

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
        data = try! threshold.get_all_share_stores_for_latest_polynomial()
    }

    override func tearDown() {
        data = nil
    }

    func test_length() {
        XCTAssertNotEqual(try! data.length(), 0)
    }

    func test_items() {
        let length = try! data.length()
        for i in 0...(length-1) {
            _ = try! data.getAt(index: i)
        }
    }
}
