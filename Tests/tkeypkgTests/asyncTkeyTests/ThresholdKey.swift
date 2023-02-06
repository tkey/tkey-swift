//
//  ThresholdKey.swift
//  
//
//  Created by pepper on 2023/02/06.
//

import XCTest
@testable import tkey_pkg


final class ThresholdKey_asyncTest: XCTestCase {
    func test_generate_and_delete_shares_async() {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        var key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        
        let dispatchedGroup = DispatchGroup()
        var successCount = 0
        var shareIndexes: [String] = []
        for i in 0..<5 {
            dispatchedGroup.enter()
            threshold_key.generateNewShareAsync { (result) in
                switch result {
                case .success(let share):
                    let idx = share.hex
                    print(idx)
                    shareIndexes.append(idx)
                    successCount += 1
                case .failure:
                    print("Iteration \(i) failed")
                }
                dispatchedGroup.leave()
            }
        }
        dispatchedGroup.notify(queue: .main) {
            _ = try! threshold_key.reconstruct()
            XCTAssertEqual(successCount, 5)
            key_details = try! threshold_key.get_key_details()
            XCTAssertEqual(key_details.total_shares, 7)
        }
        var delSuccessCount = 0
        dispatchedGroup.notify(queue: .main) {

            for i in 0..<5 {
                dispatchedGroup.enter()
                threshold_key.deleteShareAsync(share_index: shareIndexes[i]) { (result) in
                    switch result {
                    case .success:
                        delSuccessCount += 1
                    case .failure:
                        print("Iteration \(i) failed")
                    }
                    dispatchedGroup.leave()
                }
            }
        }
        
        dispatchedGroup.notify(queue: .main) {
            XCTAssertEqual(delSuccessCount, 5)
            key_details = try! threshold_key.get_key_details()
            XCTAssertEqual(key_details.total_shares, 2)
        }
    }
    
    func test_input_shares_async() {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        var key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        
        let dispatchedGroup = DispatchGroup()
        var successCount = 0
        for i in 0..<5 {
            dispatchedGroup.enter()
            threshold_key.generateNewShareAsync { (result) in
                switch result {
                case .success(let share):
                    let index = share.hex
                    let shareOut = try! threshold_key.output_share(shareIndex: index, shareType: nil)
                    threshold_key.inputShareAsync(share: shareOut, shareType: nil) { (result) in
                        switch result{
                            case .success:
                                successCount += 1
                            case .failure:
                                print("Iteration \(i) failed")
                        }
                    }
                case .failure:
                    print("Iteration \(i) failed")
                }
                dispatchedGroup.leave()
            }
        }
        dispatchedGroup.notify(queue: .main) {
            _ = try! threshold_key.reconstruct()
            XCTAssertEqual(successCount, 5)
            key_details = try! threshold_key.get_key_details()
            XCTAssertEqual(key_details.total_shares, 7)
        }
    }
}