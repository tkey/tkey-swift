import XCTest
import Foundation
@testable import tkey_pkg
import Foundation

final class tkey_pkgShareStoreMapTests: XCTestCase {
    private var data: ShareStoreMap!
    
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

        _ = try! await threshold.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold.reconstruct()
        let share = try! await threshold.generate_new_share()
        data = share.share_store
    }
    
    override func tearDown() {
        data = nil
    }
    
    func test_share_stores() {
        XCTAssertNotEqual(data.share_maps.count, 0)
    }
}
