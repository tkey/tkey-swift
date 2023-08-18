import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgPrivateKeyModuleTests: XCTestCase {
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
        let result = try! PrivateKeysModule.get_private_key_accounts(thresholdKey: thresholdKey)
        XCTAssertEqual(result.count, 0)
        let key1 = try! PrivateKey.generate()
        let key2 = try! PrivateKey.generate()
        _ = try! await PrivateKeysModule.set_private_key(thresholdKey: thresholdKey, key: key1.hex, format: "secp256k1n")
        XCTAssertEqual(try! PrivateKeysModule.get_private_key_accounts(thresholdKey: thresholdKey), [key1.hex])
        _ = try! await PrivateKeysModule.set_private_key(thresholdKey: thresholdKey, key: key2.hex, format: "secp256k1n")
        XCTAssertEqual(try! PrivateKeysModule.get_private_key_accounts(thresholdKey: thresholdKey), [key1.hex, key2.hex])
        let keys = try! PrivateKeysModule.get_private_keys(thresholdKey: thresholdKey)
        XCTAssertEqual(keys[0].privateKey, key1.hex)
        XCTAssertEqual(keys[0].type, "secp256k1n")
        XCTAssertEqual(keys[1].privateKey, key2.hex)
        XCTAssertEqual(keys[0].type, "secp256k1n")
        XCTAssertNotEqual(keys[0].id, keys[1].id)
        _ = try! await PrivateKeysModule.set_private_key(thresholdKey: thresholdKey, key: nil, format: "secp256k1n")
        XCTAssertEqual(try! PrivateKeysModule.get_private_key_accounts(thresholdKey: thresholdKey).count, 3)
        let tkey_store = try! thresholdKey.get_tkey_store(moduleName: "privateKeyModule")
        let id = tkey_store[0]["id"] as! String
        let item = try! thresholdKey.get_tkey_store_item(moduleName: "privateKeyModule", id: id)["privateKey"] as! String
        XCTAssertEqual(key1.hex, item)
    }
}
