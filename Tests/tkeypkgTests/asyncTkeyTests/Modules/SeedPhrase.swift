//
//  SeedPhrase.swift
//  
//
//  Created by pepper on 2023/02/07.
//

import XCTest
@testable import tkey_pkg

final class SeedPhrase_asyncTest: XCTestCase {
    let seedPhraseList : [String] = ["climb crisp rare radio dress brother dolphin bless chase disagree force razor",
                                     "giggle razor salon blouse result blouse urge burst urban rain blade decide",
                                     "direct powder wasp shed lift machine feed lab range intact dish rigid",
                                     "seed sock milk update focus rotate barely fade car face mechanic mercy",
                                     "object brass success calm lizard science syrup planet exercise parade honey impulse"]
    func test_set_and_delete_multiple_seed_phrase_async_manual_sync_true() {
        test_set_and_delete_multiple_seed_phrase_async(mode: true)
    }
    
    func test_set_and_delete_multiple_seed_phrase_async_manual_sync_false() {
        test_set_and_delete_multiple_seed_phrase_async(mode: false)
    }
    
    func test_set_and_delete_multiple_seed_phrase_async(mode: Bool){
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        
//        Check the seedphrase module is empty
        var seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 0)
        
        //set seed phrases asynchronously
        let dispatchedGroup = DispatchGroup()
        var successCount = 0
        for i in 0..<5 {
            dispatchedGroup.enter()
            SeedPhraseModule.setSeedPhraseAsync(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseList[i], number_of_wallets: 0){ (result) in
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
        XCTAssertEqual(successCount, 5)
        seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 5)
        
        // now try delete seed phrases
        var delsuccessCount = 0
        for i in 0..<5 {
            dispatchedGroup.enter()
            SeedPhraseModule.deleteSeedPhraseAsync(threshold_key: threshold_key, phrase: seedPhraseList[i]) { (result) in
                switch result {
                case .success:
                    delsuccessCount += 1
                case .failure:
                    print("Iteration \(i) failed")
                }
                dispatchedGroup.leave()
            }
        }
        dispatchedGroup.wait()
        XCTAssertEqual(delsuccessCount, 5)
        seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 0)
        
    }
    func test_change_seed_phrase_async_manual_sync_true() {
        test_change_seed_phrase_async(mode: true)
    }
    
    func test_change_seed_phrase_async_manual_sync_false() {
        test_change_seed_phrase_async(mode: false)
    }
    
    func test_change_seed_phrase_async(mode: Bool){
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseList[0], number_of_wallets: 0)
        var seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 1)
        
        //change seed phrases asynchronously
        let dispatchedGroup = DispatchGroup()
        var successCount = 0
        for i in 1..<5 {
            dispatchedGroup.enter()
            SeedPhraseModule.changeSeedPhraseAsync(threshold_key: threshold_key, old_phrase: seedPhraseList[i-1], new_phrase: seedPhraseList[i]){ (result) in
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
        XCTAssertEqual(successCount, 4)
        seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult[0].seedPhrase, seedPhraseList[4])
    }
}
