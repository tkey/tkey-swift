import XCTest
import Foundation
@testable import tkey_swift
import Foundation

final class tkey_pkgShareTransferModuleTests: XCTestCase {
    private var threshold_key: ThresholdKey!
    private var threshold_key2: ThresholdKey!
    private var k1: KeyReconstructionDetails!
    
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
        k1 = try! await threshold.reconstruct()
        threshold_key = threshold
        let threshold2 = try! ThresholdKey(storage_layer: storage_layer, service_provider: service_provider, enable_logging: false, manual_sync: false)
        _ = try! await threshold2.initialize()
        threshold_key2 = threshold2
        
    }
    
    override func tearDown() {
        threshold_key = nil
        threshold_key2 = nil
        k1 = nil
    }
    
    func test_share_transfer_store_and_encryption_key_retrieval() async
    {
        XCTAssertEqual("", try! ShareTransferModule.get_current_encryption_key(threshold_key: threshold_key2));
        _ = try! await ShareTransferModule.request_new_share(threshold_key: threshold_key2, user_agent: "", available_share_indexes: "[]");
        XCTAssertNotEqual("", try! ShareTransferModule.get_current_encryption_key(threshold_key: threshold_key2));
        let store = try! await ShareTransferModule.get_store(threshold_key: threshold_key)
        let lookup = try! await ShareTransferModule.look_for_request(threshold_key: threshold_key)
        let enc_pub_key = lookup[0]
        _ = try! await ShareTransferModule.delete_store(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key)
        _ = try! await ShareTransferModule.set_store(threshold_key: threshold_key, store: store)
        _ = try! await ShareTransferModule.get_store(threshold_key: threshold_key)
        try! ShareTransferModule.cleanup_request(threshold_key: threshold_key2)
        XCTAssertEqual("", try! ShareTransferModule.get_current_encryption_key(threshold_key: threshold_key2));
    }
    
    func test_approve_with_index() async {
        let request_enc = try! await ShareTransferModule.request_new_share(threshold_key: threshold_key2, user_agent: "agent", available_share_indexes: "[]")
        let lookup = try! await ShareTransferModule.look_for_request(threshold_key: threshold_key)
        let encPubKey = lookup[0]
        let newShare = try! await threshold_key.generate_new_share()
        try! await ShareTransferModule.approve_request_with_share_index(threshold_key: threshold_key, enc_pub_key_x: encPubKey, share_index: newShare.hex)
        _ = try! await ShareTransferModule.add_custom_info_to_request(threshold_key: threshold_key2, enc_pub_key_x: request_enc, custom_info: "test info")
        _ = try! await ShareTransferModule.request_status_check(threshold_key: threshold_key2, enc_pub_key_x: request_enc, delete_request_on_completion: true)
        
        let k2 = try! await threshold_key2.reconstruct()
        
        XCTAssertEqual(k1.key, k2.key)
    }
    
    func test_approve() async {
        let request_enc = try! await ShareTransferModule.request_new_share(threshold_key: threshold_key2, user_agent: "agent", available_share_indexes: "[]")
        let lookup = try! await ShareTransferModule.look_for_request(threshold_key: threshold_key)
        let enc_pub_key = lookup[0]
        var share_store: ShareStore? = nil
        let new_share = try! await threshold_key.generate_new_share()
        for (index, share) in new_share.share_store.share_maps {
            if index == new_share.hex {
                share_store = share
            }
        }
        try! await ShareTransferModule.approve_request(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key, share_store: share_store!)
        _ = try! await ShareTransferModule.request_status_check(threshold_key: threshold_key2, enc_pub_key_x: request_enc, delete_request_on_completion: true)
        let k2 = try! await threshold_key2.reconstruct()
        
        XCTAssertEqual(k1.key, k2.key)
    }
}
