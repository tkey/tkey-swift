import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgPublicPolynomialTests: XCTestCase {
    private var data: PublicPolynomial!
    private var share_indexes: [String]!

    override func setUp() async throws {
        let postboxKey = try! PrivateKey.generate()
        let storageLayer = try! StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2)
        let serviceProvider = try! ServiceProvider(enableLogging: true, postboxKey: postboxKey.hex)
        let threshold = try! ThresholdKey(
            storageLayer: storageLayer,
            serviceProvider: serviceProvider,
            enableLogging: true,
            manualSync: false
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
        for index in share_indexes {
            _ = try! data.polyCommitmentEval(index: index)
        }
    }
}
