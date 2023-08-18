import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgKeyDetailsTests: XCTestCase {
    private var data: KeyDetails!

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

        data = try! await threshold.initialize()
    }

    override func tearDown() {
        data = nil
    }

    func test_public_key_point() {
        XCTAssertNotEqual(try! data.pubKey.getPublicKey(format: .ellipticCompress).count, 0)
    }

    func test_threshold() {
        XCTAssertNotEqual(data.threshold, 0)
    }

    func test_required_shares() {
        XCTAssertEqual(data.requiredShares, 0)
    }

    func test_total_shares() {
        XCTAssertNotEqual(data.totalShares, 0)
    }

    func test_share_descriptions() {
        XCTAssertNotEqual(data.shareDescriptions.count, 0)
    }
}
