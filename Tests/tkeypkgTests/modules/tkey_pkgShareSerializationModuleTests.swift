import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgShareSerializationModuleTests: XCTestCase {
    private var thresholdKey: ThresholdKey!

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
        thresholdKey = threshold
    }

    override func tearDown() {
        thresholdKey = nil
    }

    func test() async {
        let share_index = try! await thresholdKey.generate_new_share()
        let share = try! thresholdKey.output_share(shareIndex: share_index.hex, shareType: "mnemonic")
        let deserialize = try! ShareSerializationModule.deserialize_share(thresholdKey: thresholdKey, share: share, format: "mnemonic")
        let serialize = try! ShareSerializationModule.serialize_share(thresholdKey: thresholdKey, share: deserialize, format: "mnemonic")
        XCTAssertEqual(share, serialize)

        // share serialization with share, test with nil type format
        let share_index2 = try! await thresholdKey.generate_new_share()
        let shareOut = try! thresholdKey.output_share(shareIndex: share_index2.hex)
        let phrase2 = try! ShareSerializationModule.serialize_share(thresholdKey: thresholdKey, share: shareOut)
        let deserializedShare = try! ShareSerializationModule.deserialize_share(thresholdKey: thresholdKey, share: phrase2)
        XCTAssertEqual(shareOut, deserializedShare)
    }
}
