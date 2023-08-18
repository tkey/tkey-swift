import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgLocalMetadataTransitionsTests: XCTestCase {
    private var data: LocalMetadataTransitions!

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
        let share = try! await threshold.generate_new_share()
        _ = try! await threshold.delete_share(shareIndex: share.hex)
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
