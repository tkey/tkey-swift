import XCTest
import Foundation
@testable import tkey_swift
import Foundation

final class tkey_pkgMetadataTests: XCTestCase {
    private var data: Metadata!
    
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
        data = try! threshold.get_metadata()
    }
    
    override func tearDown() {
        data = nil
    }
    
    func test_export() {
        let export = try! data.export()
        let meta = try! Metadata.init(json: export)
        let meta_export = try! meta.export()
        XCTAssertEqual(export, meta_export)
    }
}
