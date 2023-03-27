import XCTest
import Foundation
@testable import tkey_pkg
import Foundation

final class tkey_pkgGenerateShareStoreResultTests: XCTestCase {
    private var data: GenerateShareStoreResult!
    
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
        data = try! await threshold.generate_new_share()
    }
    
    override func tearDown() {
        data = nil
    }
    
    func test_index() {
        XCTAssertNotEqual(data.hex.count,0)
    }
    
    func test_share_store_map() {
        XCTAssertNotEqual(data.share_store.share_maps.count,0)
    }
}
