import XCTest
import Foundation
@testable import tkey
import Foundation

final class tkey_pkgPublicPolynomialTests: XCTestCase {
    private var data: PublicPolynomial!
    private var share_indexes: [String]!
    
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
        data = try! threshold.reconstruct_latest_poly().getPublicPolynomial()
        share_indexes = try! threshold.get_shares_indexes()
        XCTAssertNotEqual(share_indexes.count, 0)
    }
    
    override func tearDown() {
        data = nil
    }
    
    func test_get_threshold() {
        XCTAssertNotEqual(try! data.getThreshold(), 0)
    }
    
    func test_commitment_eval() {
        for index in share_indexes
        {
            _ = try! data.polyCommitmentEval(index: index)
        }
    }
}
