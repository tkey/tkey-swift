import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgMetadataTests: XCTestCase {
    private var data: Metadata!

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
