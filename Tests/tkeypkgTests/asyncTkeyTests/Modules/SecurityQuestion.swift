//
//  SecurityQuestion.swift
//  
//
//  Created by pepper on 2023/02/06.
//

import XCTest
@testable import tkey_pkg

final class SecurityQuestion_asyncTest: XCTestCase {
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
        
        let question = ["q1","q2","q3"]
        let answer : [String] = ["test1","test2","test3"]
        
        let dispatchedGroup = DispatchGroup()
        var successCount = 0
        //only one share should be created
        for i in 0..<3 {
            dispatchedGroup.enter()
            SecurityQuestionModule.generateNewShareAsync(threshold_key: threshold_key, questions: question[i], answer: answer[i]) { (result) in
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
        XCTAssertEqual(successCount, 1)
        key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 3)
        
        let get_question = try! SecurityQuestionModule.get_questions(threshold_key: threshold_key)
        XCTAssertEqual(get_question, question[0])
        let get_answer = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual(get_answer, answer[0])
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
        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        
        let question = "test question"
        let original_answer = "test answer"
        let answer : [String] = ["test1","test2","test3"]
        
        // generate new security share
        let _ = try! SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question, answer: original_answer)
        
        let dispatchedGroup = DispatchGroup()
        var successCount = 0
        for i in 0..<3 {
            dispatchedGroup.enter()
            SecurityQuestionModule.changeQuestionAndAnswerAsync(threshold_key: threshold_key, questions: question, answer: answer[i]) { (result) in
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
        XCTAssertEqual(successCount, 3)
        // check the answer was changed to the last tried one
        let get_answer = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual(get_answer, answer[2])
    }
}
