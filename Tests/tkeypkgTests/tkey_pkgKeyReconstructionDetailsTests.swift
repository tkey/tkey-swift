import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgKeyReconstructionDetailsTests: XCTestCase {
    private var data: KeyReconstructionDetails!

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
        data = try! await threshold.reconstruct()
    }

    override func tearDown() {
        data = nil
    }

    func test_get_key() {
        XCTAssertNotEqual(data.key.count, 0)
    }

    func test_get_all_keys() {
        XCTAssertEqual(data.allKeys.count, 0)
    }

    func test_get_seed_phrase() {
        XCTAssertNotEqual(data.seedPhrase.count, 0)
    }
}
