import XCTest
import Foundation
@testable import tkey_pkg
import Foundation

final class tkey_pkgShareStoreTests: XCTestCase {
    private var data: ShareStore!
    
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
        let indexes = try! threshold.get_shares_indexes()
        data = try! threshold.output_share_store(shareIndex: indexes.last!, polyId: nil)
    }
    
    override func tearDown() {
        data = nil
    }
    
    func test_share() {
        XCTAssertNotEqual(try! data.share().count, 0)
    }
    
    func test_polnomial_id() {
        XCTAssertNotEqual(try! data.polynomial_id().count, 0)
    }
    
    func test_share_index() {
        XCTAssertNotEqual(try! data.share_index().count, 0)
    }
    
    func test_jsonify() {
        let json = try! data.toJsonString()
        XCTAssertNotEqual(json.count, 0)
        let new_store = try! ShareStore.init(json: json);
        XCTAssertEqual(try! data.share_index(), try! new_store.share_index())
    }
}
