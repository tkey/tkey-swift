import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgKeyDetailsTests: XCTestCase {
    private var data: KeyDetails!

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

        data = try! await threshold.initialize()
    }

    override func tearDown() {
        data = nil
    }

    func test_public_key_point() {
        XCTAssertNotEqual(try! data.pubKey.getPublicKey(format: .EllipticCompress).count, 0)
    }

    func test_threshold() {
        XCTAssertNotEqual(data.threshold, 0)
    }

    func test_required_shares() {
        XCTAssertEqual(data.required_shares, 0)
    }

    func test_total_shares() {
        XCTAssertNotEqual(data.total_shares, 0)
    }

    func test_share_descriptions() {
        XCTAssertNotEqual(data.share_descriptions.count, 0)
    }
}
