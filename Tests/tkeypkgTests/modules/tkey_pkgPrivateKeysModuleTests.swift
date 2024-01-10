import XCTest
import Foundation
@testable import tkey_swift
import Foundation

final class tkey_pkgPrivateKeyModuleTests: XCTestCase {
    private var threshold_key: ThresholdKey!
    
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
        threshold_key = threshold
    }
    
    override func tearDown() {
        threshold_key = nil
    }
    
    func test() async {
        let result = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result.count, 0)
        let key1 = try! PrivateKey.generate()
        let key2 = try! PrivateKey.generate()
        _ = try! await PrivateKeysModule.set_private_key(threshold_key: threshold_key, key:     key1.hex, format: "secp256k1n")
        XCTAssertEqual(try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key),[key1.hex])
        _ = try! await PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: key2.hex, format: "secp256k1n")
        XCTAssertEqual(try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key), [key1.hex, key2.hex])
        let keys = try! PrivateKeysModule.get_private_keys(threshold_key: threshold_key)
        XCTAssertEqual(keys[0].privateKey,key1.hex)
        XCTAssertEqual(keys[0].type,"secp256k1n")
        XCTAssertEqual(keys[1].privateKey,key2.hex)
        XCTAssertEqual(keys[0].type,"secp256k1n")
        XCTAssertNotEqual(keys[0].id, keys[1].id)
        _ = try! await PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: nil, format: "secp256k1n")
        XCTAssertEqual(try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key).count, 3)
        let tkey_store = try! threshold_key.get_tkey_store(moduleName: "privateKeyModule")
        let id = tkey_store[0]["id"] as! String
        let item = try! threshold_key.get_tkey_store_item(moduleName: "privateKeyModule", id: id)["privateKey"] as! String
        XCTAssertEqual(key1.hex,item)
    }
}
