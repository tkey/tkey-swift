import XCTest
@testable import tkey_pkg

final class tkey_pkgTests: XCTestCase {
    func testExample() throws {
        let curve_n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let key1 = try! PrivateKey.generate(curve_n: curve_n)
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)

        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex, curve_n: curve_n)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)
        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false, curve_n: curve_n)
        _ = try! threshold_key.reconstruct(curve_n: curve_n)
        let metadata = try! threshold_key.get_metadata()
        let json = try! metadata.export()
        XCTAssertGreaterThan(json.lengthOfBytes(using: .utf8), 0)
        _ = try! Metadata.init(json: json)
    }
}
