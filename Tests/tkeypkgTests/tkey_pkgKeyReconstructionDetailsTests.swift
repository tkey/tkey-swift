import XCTest
import Foundation
@testable import tkey_pkg
import Foundation

final class tkey_pkgKeyReconstructionDetailsTests: XCTestCase {
    private var data: KeyReconstructionDetails!
    
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
        data = try! await threshold.reconstruct()
    }
    
    override func tearDown() {
        data = nil
    }
    
    func test_get_key() {
        XCTAssertNotEqual(data.key.count,0)
    }
    
    func test_get_all_keys() {
        XCTAssertEqual(data.all_keys.count,0)
    }
    
    func test_get_seed_phrase() {
        XCTAssertNotEqual(data.seed_phrase.count,0)
    }
}
