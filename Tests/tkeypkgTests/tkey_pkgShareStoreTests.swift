import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgShareStoreTests: XCTestCase {
    private var data: ShareStore!

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
        let new_store = try! ShareStore.init(json: json)
        XCTAssertEqual(try! data.share_index(), try! new_store.share_index())
    }
}
