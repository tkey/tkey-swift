import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgGenerateShareStoreResultTests: XCTestCase {
    private var data: GenerateShareStoreResult!

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
        data = try! await threshold.generate_new_share()
    }

    override func tearDown() {
        data = nil
    }

    func test_index() {
        XCTAssertNotEqual(data.hex.count, 0)
    }

    func test_share_store_map() {
        XCTAssertNotEqual(data.shareStore.shareMaps.count, 0)
    }
}
