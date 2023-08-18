import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgKeyPointTests: XCTestCase {
    private var data: KeyPoint!

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

        let key_details = try! await threshold.initialize()
        data = key_details.pubKey
    }

    override func tearDown() {
        data = nil
    }

    func test_get_x() {
        XCTAssertNotEqual(try! data.getX().count, 0)
    }

    func test_get_y() {
        XCTAssertNotEqual(try! data.getY().count, 0)
    }

    func test_required_shares() {
        XCTAssertNotEqual(try data.getPublicKey(format: .ellipticCompress).count, 0)
    }

    func test_create_x_y() {
        let point = try! KeyPoint(valueX: try! data.getX(), valueY: try! data.getY())
        XCTAssertEqual(try! point.getX(), try! data.getX())
        XCTAssertEqual(try! point.getY(), try! data.getY())
    }
}
