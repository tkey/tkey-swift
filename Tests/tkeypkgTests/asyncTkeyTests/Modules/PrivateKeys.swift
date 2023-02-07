//
//  PrivateKeys.swift
//  
//
//  Created by pepper on 2023/02/07.
//

import XCTest
@testable import tkey_pkg

final class PrivateKey_asyncTest: XCTestCase {
    func test_generate_multiple_private_key_async(){
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
        
        //prepare the private key list
        var pklist: [String] = []
        for _ in 0..<5 {
            let pk = try! PrivateKey.generate().hex
            pklist.append(pk)
        }
        
        //set private keys asynchronously
        let dispatchedGroup = DispatchGroup()
        var successCount = 0
        for i in 0..<5 {
            dispatchedGroup.enter()
            PrivateKeysModule.setPrivateKeyAsync(threshold_key: threshold_key, key: pklist[i], format: "secp256k1n"){ (result) in
                switch result {
                case .success:
                    successCount += 1
                case .failure:
                    print("Iteration \(i) failed")
                }
                dispatchedGroup.leave()
            }
        }
        
        dispatchedGroup.wait()
        _ = try! threshold_key.reconstruct()
        XCTAssertEqual(successCount, 5)
        key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        let pknum = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key).count
        XCTAssertEqual(pknum, 5)
    }
}
