import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgThresholdKeyTests: XCTestCase {
    func test_basic_threshold_key_reconstruct() async {
        let postbox = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)
        let key = try! PrivateKey.generate()
        _ = try! await threshold_key.initialize()
        _ = try! await threshold_key.reconstruct()
    }
    
    func test_basic_threshold_key_method_test() async {
        let postbox = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)
        let key = try! PrivateKey.generate()
        _ = try! await threshold_key.initialize()
        _ = try! await threshold_key.reconstruct()
        _ = try! threshold_key.get_key_details()
        _ = try! threshold_key.get_last_fetched_cloud_metadata()
        _ = try! threshold_key.get_local_metadata_transitions()
        let share = try! await threshold_key.generate_new_share()
        let output = try! threshold_key.output_share(shareIndex: share.hex, shareType: nil)
        _ = try! threshold_key.output_share_store(shareIndex: share.hex, polyId: nil)
        _ = try! threshold_key.share_to_share_store(share: output)
        try! await threshold_key.delete_share(share_index: share.hex)
        let share2 = try! await threshold_key.generate_new_share()
        let input = try! threshold_key.output_share(shareIndex: share2.hex, shareType: nil)
        let input_store = try! threshold_key.output_share_store(shareIndex: share2.hex, polyId: nil)
        let threshold_key2 = try! ThresholdKey.init(storage_layer: storage_layer, service_provider: service_provider, enable_logging: true, manual_sync: false)
        _ = try! await threshold_key2.initialize()
        try! await threshold_key2.input_share(share: input, shareType: nil)
        _ = try! await threshold_key2.reconstruct()
        let threshold_key3 = try! ThresholdKey.init(storage_layer: storage_layer, service_provider: service_provider, enable_logging: true, manual_sync: false)
        _ = try! await threshold_key3.initialize()
        try! await threshold_key3.input_share_store(shareStore: input_store)
        _ = try! await threshold_key3.reconstruct()
        _ = try! await threshold_key3.CRITICAL_delete_tkey()
    }
    
    func test_threshold_key_manual_sync() async {
        let postbox = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)
        let key = try! PrivateKey.generate()
        _ = try! await threshold_key.initialize()
        _ = try! await threshold_key.reconstruct()
        _ = try! await threshold_key.generate_new_share()
        _ = try! await threshold_key.sync_local_metadata_transistions()
        _ = try! await threshold_key.reconstruct()
    }
    
    func test_threshold_key_internal_queue() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! await threshold_key.initialize()
        var key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)

        //prepare the private key list
        var pklist: [String] = []
        for _ in 0..<5 {
            let pk = try! PrivateKey.generate().hex
            pklist.append(pk)
        }
        let a = pklist

        //set private keys asynchronously
        async let set5keys = Task {
            async let new_share1 = try? PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: a[0], format: "secp256k1n")
            async let new_share2 = try? PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: a[1], format: "secp256k1n")
            async let new_share3 = try? PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: a[2], format: "secp256k1n")
            async let new_share4 = try? PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: a[3], format: "secp256k1n")
            async let new_share5 = try? PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: a[4], format: "secp256k1n")
            return await [new_share1,new_share2,new_share3,new_share4, new_share5]
        }.value
        
        let _ = await set5keys
        key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        let pknum = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key).count
        XCTAssertEqual(pknum, 5)
    }
    
    func test_threshold_key_multi_instance() async {
        let postbox = try! PrivateKey.generate()
        let postbox2 = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let storage_layer2 = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox.hex)
        let service_provider2 = try! ServiceProvider(enable_logging: true, postbox_key: postbox2.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)
        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer2,
            service_provider: service_provider2,
            enable_logging: true,
            manual_sync: false)
        let key = try! PrivateKey.generate()
        _ = try! await threshold_key.initialize()
        let reconstruct1 = try! await threshold_key.reconstruct()
        let key2 = try! PrivateKey.generate()
        _ = try! await threshold_key2.initialize()
        let reconstruct2 = try! await threshold_key2.reconstruct()
        XCTAssertNotEqual(reconstruct1.key, reconstruct2.key)
    }
    
    func test_encrypt_decrypt() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! await threshold_key.initialize()
        _ = try! await threshold_key.reconstruct()
        
        let msg = "this is the test msg"
        let encrypted = try! threshold_key.encrypt(msg: msg)
        let decrypted = try! threshold_key.decrypt(msg: encrypted)
        XCTAssertEqual(msg, decrypted)
    }
    
    func test_share_descriptions() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! await threshold_key.initialize()
        _ = try! await threshold_key.reconstruct()
        
        let key = "test share"
        let old_description = "test share description"
        let new_description = "new test share description"
        _ = try! await threshold_key.add_share_description(key: key, description: old_description)
        let share_description_1 = try! threshold_key.get_share_descriptions()
        XCTAssertEqual(share_description_1["test share"], ["test share description"])

        _ = try! await threshold_key.update_share_description(key: key, oldDescription: old_description, newDescription: new_description)
        let share_description_2 = try! threshold_key.get_share_descriptions()
        XCTAssertEqual(share_description_2["test share"], ["new test share description"])

        _ = try! await threshold_key.delete_share_description(key: key, description: new_description)
        let share_description_3 = try! threshold_key.get_share_descriptions()
        XCTAssertEqual(share_description_3["test share"], [])
    }
}
