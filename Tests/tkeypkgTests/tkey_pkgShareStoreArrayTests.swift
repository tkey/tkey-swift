import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgShareStoreArrayTests: XCTestCase {
    private var data: ShareStoreArray!

    override func setUp() async throws {
        let postbox_key = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox_key.hex)
        let threshold = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
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
