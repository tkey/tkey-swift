import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgLocalMetadataTransitionsTests: XCTestCase {
    private var data: LocalMetadataTransitions!

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
        let share = try! await threshold.generate_new_share()
        _ = try! await threshold.delete_share(share_index: share.hex)
        data = try! threshold.get_local_metadata_transitions()
    }

    override func tearDown() {
        data = nil
    }

    func test_export() {
        XCTAssertNotEqual(try! data.export().count, 0)
    }

    func test_create() {
        let export = try! data.export()
        _ = try! LocalMetadataTransitions.init(json: export)
    }
}
