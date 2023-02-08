//
//  ThresholdKey.swift
//
//
//  Created by pepper on 2023/02/08.
//

import XCTest
@testable import tkey_pkg


final class ShareTransfer_asyncTest: XCTestCase {
    
    func test_generate_and_delete_shares_async_manual_sync_true() {
        test_generate_and_delete_shares_async(mode: true)
    }
    
    func test_generate_and_delete_shares_async_manual_sync_false() {
        test_generate_and_delete_shares_async(mode: false)
    }
    
    
    func test_generate_and_delete_shares_async(mode: Bool) {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)

        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_reconstruction_details = try! threshold_key.reconstruct()

        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false)

        
        let user_agent = "user_agent"
        
        //Request new share n times
        let dispatchedGroup = DispatchGroup()
        var successCount = 0
        var requestList: [String] = []
        
        // only one request share should be created
        for i in 0..<3 {
            dispatchedGroup.enter()
            ShareTransferModule.requestNewShareAsync(threshold_key: threshold_key2, user_agent: user_agent, available_share_indexes: "[]") { (result) in
                switch result {
                case .success(let request):
                    successCount += 1
                    requestList.append(request)
                case .failure:
                    print("Iteration \(i) failed")
                }
                dispatchedGroup.leave()
            }
        }
        dispatchedGroup.wait()
        XCTAssertEqual(successCount, 1)
        
        //Generate new share n times
        successCount = 0
        var shareIndexes: [String] = []

        for i in 0..<3 {
            dispatchedGroup.enter()
            threshold_key.generateNewShareAsync { result in
                switch result {
                case .success(let share):
                    let idx = share.hex
                    shareIndexes.append(idx)
                    successCount += 1
                case .failure(let error):
                    print("Error in iteration \(i): \(error)")
                }
                dispatchedGroup.leave()
            }
        }
        dispatchedGroup.wait()
        _ = try! threshold_key.reconstruct()
        XCTAssertEqual(successCount, 3)
        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 5)
        
        let lookup = try! ShareTransferModule.look_for_request(threshold_key: threshold_key)
        let encPubKey = lookup[0]
        successCount = 0
        // Run approve_request_with_share_index n times asynchronously
        for i in 0..<3 {
            dispatchedGroup.enter()
            ShareTransferModule.approveRequestWithShareIndexAsync(threshold_key: threshold_key, enc_pub_key_x: encPubKey, share_index: shareIndexes[i]) { result in
                switch result {
                case .success():
                    successCount += 1
                case .failure(let error):
                    print("Error in iteration \(i): \(error)")
                }
                dispatchedGroup.leave()
            }
        }
        dispatchedGroup.wait()
        XCTAssertEqual(successCount, 3)
        // request_status_check n times asynchronously?
        _ = try! ShareTransferModule.request_status_check(threshold_key: threshold_key2, enc_pub_key_x: requestList[0], delete_request_on_completion: true)

        let key_reconstruction_details_2 = try! threshold_key2.reconstruct()

        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details_2.key)
        let key2_details = try! threshold_key2.get_key_details()
        XCTAssertEqual(key2_details.total_shares, 5)
        
    }
}
