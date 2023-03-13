import XCTest
import Foundation
@testable import tkey_pkg

final class parenet: XCTestSuite{
    
}

final class tkey_pkgTests: XCTestCase {
    func testLibraryVersion() {
        _ = try! library_version()
    }
    
    func testGenerateAndDeleteShares() async {
        await generateDeleteShare(true);
//        await generateDeleteShare(false);
    }
    
    func generateDeleteShare(_ manual_sync: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: manual_sync)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
            
        // Push 4 generate new shares to queue
        async let create4share = Task {
                async let new_share = try! threshold_key.generate_new_share();
                async let new_share2 = try! threshold_key.generate_new_share()
                async let new_share3 = try! threshold_key.generate_new_share()
                async let new_share4 = try! threshold_key.generate_new_share()
                return await [new_share,new_share2,new_share3,new_share4]
        }.value
        
        XCTAssertEqual(try! threshold_key.get_key_details().total_shares, 2)
        
        let new_share = try! await threshold_key.generate_new_share()
        let share_index = new_share.hex;
        
        _ = try! threshold_key.output_share(shareIndex: share_index, shareType: nil)
        
        try! await threshold_key.delete_share(share_index: share_index)
        
        let _ = await create4share;
        
        let key_details_3 = try! threshold_key.get_key_details()
        
        XCTAssertEqual(key_details_3.total_shares, 6)
        let getShareResult = try! threshold_key.get_shares()
        // total number of share_maps can be different with total shares within a specific map
        
        XCTAssertNil(try? threshold_key.output_share(shareIndex: share_index, shareType: nil))
    }
    
    func testDeleteTkey() async {
        await deleteTkey(false);
        await deleteTkey(true);
    }

    func deleteTkey(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold_key.reconstruct()
        
        if mode {
            try! await threshold_key.sync_local_metadata_transistions()
        }
        
        try! await threshold_key.delete_tkey()
        
        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key2.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold_key2.generate_new_share()
        let key_detail_2 = try! threshold_key2.get_key_details()
        XCTAssertEqual(key_detail_2.total_shares, 3)
    }
    
    func testThresholdInputOutputShare() async {
        await thresholdInputOutputShare(false);
        await thresholdInputOutputShare(true);
    }

    func thresholdInputOutputShare(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_reconstruction_details = try! await threshold_key.reconstruct()

        let shareStore = try! await threshold_key.generate_new_share()

        let shareOut = try! threshold_key.output_share(shareIndex: shareStore.hex, shareType: nil)

        // we initialize new thresholdkey with existing storage layer, so we sync here if manual sync is false
        if mode {
            try! await threshold_key.sync_local_metadata_transistions()
        }
        
        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false)

        try! await threshold_key2.input_share(share: shareOut, shareType: nil)

        let key2_reconstruction_details = try! await threshold_key2.reconstruct()
        XCTAssertEqual( key_reconstruction_details.key, key2_reconstruction_details.key)
    }
    
    func testShareDescription() async {
        await shareDescription(false);
        await shareDescription(true);
    }

    func shareDescription(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
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
    
    func testShareStore() async {
        await shareStore(false);
        await shareStore(true);
    }

    func shareStore(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_reconstruction_details = try! await threshold_key.reconstruct()
        
        // generate new share
        let new_share = try! await threshold_key.generate_new_share();

        let store = try! threshold_key.output_share_store(shareIndex: new_share.hex, polyId: nil)
        
        // do basic sharestore test here
        _ = try! store.toJsonString()
        _ = try! store.share()
        let idx = try! store.share_index()
        XCTAssertEqual(idx, new_share.hex)

        // test get_share_index
        let idxArr = try! threshold_key.get_shares_indexes()
        var count = 0
        for i in idxArr {
            if idx == i {
                count += 1
            }
        }
        // check if we can find corresponding index in the Array
        XCTAssertEqual(count, 1)

        if mode {
            try! await threshold_key.sync_local_metadata_transistions()
        }
        
        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)
        _ = try! await threshold_key2.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        try! await threshold_key2.input_share_store(shareStore: store)
        let key_reconstruction_details2 = try! await threshold_key2.reconstruct()
        
        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details2.key)
    }
    
    func testShareToShareStore() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let share = try! await threshold_key.generate_new_share()
        let shareOut = try! threshold_key.output_share(shareIndex: share.hex, shareType: nil)
        let shareStore = try! threshold_key.share_to_share_store(share: shareOut)
        
        // check reconstruction works
        
        try! await threshold_key.input_share_store(shareStore: shareStore)
        _ = try! await threshold_key.reconstruct()
        let keyDetail = try! threshold_key.get_key_details()
        XCTAssertEqual(keyDetail.total_shares, 3)
    }
    
    func testTkeyStoreMethods() async {
        await tkeyStoreMethods(false);
        await tkeyStoreMethods(true);
    }

    func tkeyStoreMethods(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold_key.reconstruct()
        
        // set seed phrase
        let _ = try! await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: "seed sock milk update focus rotate barely fade car face mechanic mercy", number_of_wallets: 0)
        
        let tkeyStore = try! threshold_key.get_tkey_store(moduleName: "seedPhraseModule")
        let id = tkeyStore[0]["id"] as? String ?? ""
        let tkey_store_item = try? threshold_key.get_tkey_store_item(moduleName: "seedPhraseModule", id: id)
        XCTAssertNotEqual(tkey_store_item, nil)
    }
    
    func testTkeyEncryptDecrypt() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold_key.reconstruct()
        
        let msg = "this is the test msg"
        let encrypted = try! threshold_key.encrypt(msg: msg)
        let decrypted = try! threshold_key.decrypt(msg: encrypted)
        XCTAssertEqual(msg, decrypted)
    }
    
    func testSecurityQuestionModule() async {
        await securityQuestionModule(true)
        await securityQuestionModule(false)
    }

    func securityQuestionModule(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_reconstruction_details = try! await threshold_key.reconstruct()

        let question = "favorite marvel character"
        let answer = "iron man"
        let answer_2 = "captain america"

        // generate new security share
        let new_share = try! await SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question, answer: answer)
        let share_index = new_share.hex

        let sq_question = try! SecurityQuestionModule.get_questions(threshold_key: threshold_key)
        XCTAssertEqual(sq_question, question)

        let security_input_share: Bool = try! await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer)
        XCTAssertEqual(security_input_share, true)

        var input = try? await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: "ant man")
        XCTAssertNil(input)
            
        
        // change answer for already existing question
        let change_answer_result = try! await SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer_2)
        XCTAssertEqual(change_answer_result, true)

        input = try? await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer)
        XCTAssertNil(input)
        
        let security_input_share_2 = try! await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer_2)
        XCTAssertEqual(security_input_share_2, true)

        let get_answer = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual(get_answer, answer_2)

        let key_reconstruction_details_2 = try! await threshold_key.reconstruct()
        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details_2.key)

        // delete newly security share
        try! await threshold_key.delete_share(share_index: share_index)

        input = try? await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer)
        XCTAssertNil(input)

    }
    
    func testGenerateMultipleQnA() async {
        await generateMultipleQnA(true);
        await generateMultipleQnA(false);
    }
    
    func generateMultipleQnA (_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        var key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)

        let question = ["q1","q2","q3"]
        let answer : [String] = ["test1","test2","test3"]

        // only one share should be created
        async let create3share = Task {
            async let new_share = try! SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question[0], answer: answer[0]);
            async let new_share2 = try? SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question[1], answer: answer[1]);
            async let new_share3 = try? SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question[2], answer: answer[2]);
            return await [new_share, new_share2, new_share3];
        }.value
        
        _ = try! await threshold_key.reconstruct()
        key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        
        // await here for the all resolved results
        let shares = await create3share;
        XCTAssertNil(shares[1]);
        XCTAssertNil(shares[2]);
        XCTAssertNotNil(shares[0]);

        // now here it should be assured that only one share is created
        let key_details_3 = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details_3.total_shares, 3)
        let get_question = try! SecurityQuestionModule.get_questions(threshold_key: threshold_key)
        XCTAssertEqual(get_question, question[0])
        let get_answer = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual(get_answer, answer[0])
    }
    
    func testChangeAnswers() async {
        await changeAnswers(true);
        await changeAnswers(false);
    }
    
    func changeAnswers(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)

        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)

        let question = "test question"
        let original_answer = "test answer"
        let answer : [String] = ["test1","test2","test3"]

        // generate new security share
        let _ = try! await SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question, answer: original_answer)
        async let change3answers = Task {
            async let new_share = try! SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer[0]);
            async let new_share2 = try! SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer[1]);
            async let new_share3 = try! SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer[2]);
            
            return await [new_share, new_share2, new_share3];
        }.value
        
        _ = try! await threshold_key.reconstruct()
        let key_details2 = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details2.total_shares, 3)
        
        // await here for the all resolved results
        let shares = await change3answers;
        XCTAssertNotNil(shares[1]);
        XCTAssertNotNil(shares[2]);
        XCTAssertNotNil(shares[0]);

        
        // now here it should be assured that only one share is created
        let key_details_3 = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details_3.total_shares, 3)
        let get_question = try! SecurityQuestionModule.get_questions(threshold_key: threshold_key)
        XCTAssertEqual(get_question, question)
        let get_answer = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual(get_answer, answer[2])
        
        _ = try! await SecurityQuestionModule.store_answer(threshold_key: threshold_key, answer: "test")
        let answer2 = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual("test", answer2)

        }
    
    func testThresholdShareTransfer() async {
        await thresholdShareTransfer(true)
        await thresholdShareTransfer(false)
    }

    func thresholdShareTransfer (_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)

        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_reconstruction_details = try! await threshold_key.reconstruct()

        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        if mode
        {
            try! await threshold_key.sync_local_metadata_transistions()
        }
        
        _ = try! await threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false)

        let request_enc = try! await ShareTransferModule.request_new_share(threshold_key: threshold_key2, user_agent: "agent", available_share_indexes: "[]")
        let lookup = try! await ShareTransferModule.look_for_request(threshold_key: threshold_key)
        let encPubKey = lookup[0]
        let newShare = try! await threshold_key.generate_new_share()

        try! await ShareTransferModule.approve_request_with_share_index(threshold_key: threshold_key, enc_pub_key_x: encPubKey, share_index: newShare.hex)
        
        if mode
        {
            try! await threshold_key.sync_local_metadata_transistions()
        }
        
        // adding custom info should work
        _ = try! await ShareTransferModule.add_custom_info_to_request(threshold_key: threshold_key2, enc_pub_key_x: request_enc, custom_info: "test info")
        
        _ = try! await ShareTransferModule.request_status_check(threshold_key: threshold_key2, enc_pub_key_x: request_enc, delete_request_on_completion: true)
        
        let key_reconstruction_details_2 = try! await threshold_key2.reconstruct()

        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details_2.key)
    }
    
    func testshareTransferModuleDeleteStore() async {
        await shareTransferModuleDeleteStore(true)
        await shareTransferModuleDeleteStore(false)
    }

    func shareTransferModuleDeleteStore(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)

        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)

        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        if mode{
            try! await threshold_key.sync_local_metadata_transistions()
        }
        
        _ = try! await threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false)

        _ = try! await ShareTransferModule.request_new_share(threshold_key: threshold_key, user_agent: "user_agent", available_share_indexes: "[]")
        let request = try! await ShareTransferModule.get_store(threshold_key: threshold_key)
        
        //set store to other tkey with no error
        _ = try! await ShareTransferModule.set_store(threshold_key: threshold_key2, store: request)
        let lookup = try! await ShareTransferModule.look_for_request(threshold_key: threshold_key)
        
        let encPubKey = lookup[0]
        let newShare = try! await threshold_key.generate_new_share()
        let store = try! threshold_key.output_share_store(shareIndex: newShare.hex, polyId: nil)
        
        // do basic sharestore tests
        _ = try! store.toJsonString()
        _ = try! store.share()
        let idx = try! store.share_index()
        XCTAssertEqual(idx, newShare.hex)

        try! await ShareTransferModule.approve_request(threshold_key: threshold_key, enc_pub_key_x: encPubKey, share_store: store)
        // should be able to delete share request created from device 1
        _ = try! await ShareTransferModule.delete_store(threshold_key: threshold_key, enc_pub_key_x: lookup[0])
        _ = try! await ShareTransferModule.get_store(threshold_key: threshold_key)
    }
    
    func testPrivateKeyModule() async {
        await privateKeyModule(true);
        await privateKeyModule(false);
    }

    func privateKeyModule(_ mode: Bool) async {
        let key1 = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode
        )

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold_key.reconstruct()

        let result = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result.count, 0)
        
        var pknum = try! PrivateKeysModule.get_private_keys(threshold_key: threshold_key).count
        XCTAssertEqual(pknum, 2)

        let key_module = try! PrivateKey.generate()
        let key_module2 = try! PrivateKey.generate()
        // Done setup
        // Try set and get privatekey from privatekey module
        _ = try! await PrivateKeysModule.set_private_key(threshold_key: threshold_key, key:     key_module.hex, format: "secp256k1n")
        let result_1 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result_1, [key_module.hex] )

        // Try set 2nd privatekey
        _ = try! await PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: key_module2.hex, format: "secp256k1n")
        let result_2 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result_2, [key_module.hex, key_module2.hex])

        // Try set privateKey module with nil key
        _ = try! await PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: nil, format: "secp256k1n")
        let result_3 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result_3.count, 3)
        
        

        // try PrivateKeysModule.remove_private_key()
        // Reconstruct on second instance and check value ?

    }
    
    func testSetMultiPrivateKeys() async {
        await setMultiPrivateKeys(true);
        await setMultiPrivateKeys(false);
    }
    
    func setMultiPrivateKeys(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
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
    
    func testPolynomial() async {
        await polynomial(true);
        await polynomial(false);
    }

    func polynomial(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)
        
        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        
        let poly = try! threshold_key.reconstruct_latest_poly()
        
        let pub_poly = try! poly.getPublicPolynomial();
        let threshold_count = try! pub_poly.getThreshold();
        XCTAssertEqual(threshold_count, 2 );
        
        // get all share store
        let share_store = try! threshold_key.get_all_share_stores_for_latest_polynomial();
        let store = try! share_store.getShareStoreAtIndex(index: 0)
        XCTAssertNotNil(store)
        
        let length = try! share_store.getShareStoreArrayLength()
        XCTAssertEqual( length, 2 );
        
        let share_index_array = ["c9022864e78c175beb9931ba136233fce416ece4c9af258ac9af404f7436c281", "8cd35d2d246e475de2413732c2d134d39bb51a1ed07cb5b1d461b5184c62c1b6", "6e0ab0cb7e47bdce6b08c043ee449d94c3addf33968ae79b4c8d7014238c46e4"]

        let json_share_idx = try! JSONSerialization.data(withJSONObject: share_index_array, options: [])
        let share_idx_string = String(data: json_share_idx, encoding: String.Encoding.utf8)
        
        let share_map = try! poly.generateShares(share_index: share_idx_string!);
        let points_arr =  KeyPointArray.init();
        XCTAssertEqual(share_map.share_map.count, 3 );
        
        for item in share_map.share_map {
            let share_index = item.key;
            
            let pub_poly = try! poly.getPublicPolynomial();
            let point = try! pub_poly.polyCommitmentEval(index: share_index);
            XCTAssertNotNil(try! point.getX());
            XCTAssertNotNil(try! point.getY());
            try! points_arr.insertKeyPoint(point: point);
        }
        
        let len = try! points_arr.getKeyPointArrayLength()
        XCTAssertEqual(len, 3)
        
        // simple update test
        for item in share_map.share_map {
            let share_index = item.key;
            
            let pub_poly = try! poly.getPublicPolynomial();
            let point = try! pub_poly.polyCommitmentEval(index: share_index);
            XCTAssertNotNil(try! point.getX());
            XCTAssertNotNil(try! point.getY());
            try! points_arr.updateKeyPoint(point: point, index: 0)
        }
        
        // remove test
        _ = try! points_arr.removeKeyPoint(index: 2)
        let len2 = try! points_arr.getKeyPointArrayLength()
        XCTAssertEqual(len2, 2)
        
        
        let lagrange_poly = try! Lagrange.lagrange(points: points_arr);
        XCTAssertNotNil(lagrange_poly);
    }
    
    func testSeedPhraseModule() async {
        await seedPhraseModule(true);
        await seedPhraseModule(false);
    }

    func seedPhraseModule(_ mode: Bool) async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode
            )

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold_key.reconstruct()
        let seedPhraseToSet = "seed sock milk update focus rotate barely fade car face mechanic mercy"
        let seedPhraseToSet2 = "object brass success calm lizard science syrup planet exercise parade honey impulse"
        
//      Check the seedphrase module is empty
        let seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 0 )

//        set and get seedphrases
        try! await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet, number_of_wallets: 0)
        let seedResult_2 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_2[0].seedPhrase, seedPhraseToSet )

        do {
            try await SeedPhraseModule.delete_seedphrase(threshold_key: threshold_key, phrase: seedPhraseToSet2)
            XCTAssertTrue( false )
        }catch{}
//        Try delete unknown seedphrase - expect fail

//        Try to set and get 2nd seedphrases
        try! await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet2, number_of_wallets: 0)
        let seedResult_3 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_3[0].seedPhrase, seedPhraseToSet )
        XCTAssertEqual(seedResult_3[1].seedPhrase, seedPhraseToSet2 )

        do {
            try await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet2, number_of_wallets: 0)
            XCTAssertTrue( false )
            //        Try set seedphrase with existing seed phrase
        } catch {}
        
//        Try set seedphrase with nil
        try! await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: nil, number_of_wallets: 0)
        let seedResult_4 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_4.count, 3 )

//        Try reconstruct 2nd Tkey instance to check if seed phrase is persistance
    }
    
    func testsetAndGetMultipleSeedPhrases() async {
        await setAndGetMultipleSeedPhrases(true)
        await setAndGetMultipleSeedPhrases(false)
    }
    
    func setAndGetMultipleSeedPhrases(_ mode: Bool) async {
        let seedPhraseList : [String] = ["climb crisp rare radio dress brother dolphin bless chase disagree force razor",
                                             "giggle razor salon blouse result blouse urge burst urban rain blade decide",
                                             "direct powder wasp shed lift machine feed lab range intact dish rigid",
                                             "seed sock milk update focus rotate barely fade car face mechanic mercy",
                                             "object brass success calm lizard science syrup planet exercise parade honey impulse"]
        
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)

        async let set5phrase = Task {
            async let set1: ()? = try? SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseList[0], number_of_wallets: 0);
            async let set2: ()? = try? SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseList[1], number_of_wallets: 0);
            async let set3: ()? = try? SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseList[2], number_of_wallets: 0);
            async let set4: ()? = try? SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseList[3], number_of_wallets: 0);
            async let set5: ()? = try? SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseList[4], number_of_wallets: 0);

            return await [set1,set2,set3,set4,set5]
        }.value
        
        //Check the seedphrase module is empty
        let seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 0)
        
        let _ = await set5phrase;
        

        
        XCTAssertEqual(try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key).count, 5)

        // now try delete seed phrases
        async let del5phrase = Task {
            async let del1: ()? = try? SeedPhraseModule.delete_seedphrase(threshold_key: threshold_key, phrase: seedPhraseList[0]);
            async let del2: ()? = try? SeedPhraseModule.delete_seedphrase(threshold_key: threshold_key, phrase: seedPhraseList[1]);
            async let del3: ()? = try? SeedPhraseModule.delete_seedphrase(threshold_key: threshold_key, phrase: seedPhraseList[2]);
            async let del4: ()? = try? SeedPhraseModule.delete_seedphrase(threshold_key: threshold_key, phrase: seedPhraseList[3]);
            async let del5: ()? = try? SeedPhraseModule.delete_seedphrase(threshold_key: threshold_key, phrase: seedPhraseList[4]);

            return await [del1,del2,del3,del4,del5]
        }.value

        let _ = await del5phrase;
        
        XCTAssertEqual(try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key).count, 0)
    }
    
    func testChangeSeedPhrases() async {
        await changeSeedPhrases(true);
        await changeSeedPhrases(false);
    }
    
    func changeSeedPhrases(_ mode: Bool) async {
        let seedPhraseList : [String] = ["climb crisp rare radio dress brother dolphin bless chase disagree force razor",
                                             "giggle razor salon blouse result blouse urge burst urban rain blade decide",
                                             "direct powder wasp shed lift machine feed lab range intact dish rigid",
                                             "seed sock milk update focus rotate barely fade car face mechanic mercy",
                                             "object brass success calm lizard science syrup planet exercise parade honey impulse"]
        
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: mode)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        try! await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseList[0], number_of_wallets: 0)
        var seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 1)

        //change seed phrase 4 times sequentially, as the order needs to be ensured
        let _ = try! await SeedPhraseModule.change_phrase(threshold_key: threshold_key, old_phrase: seedPhraseList[0], new_phrase: seedPhraseList[1]);
        let _ = try! await SeedPhraseModule.change_phrase(threshold_key: threshold_key, old_phrase: seedPhraseList[1], new_phrase: seedPhraseList[2]);
        let _ = try! await SeedPhraseModule.change_phrase(threshold_key: threshold_key, old_phrase: seedPhraseList[2], new_phrase: seedPhraseList[3]);
        let _ = try! await SeedPhraseModule.change_phrase(threshold_key: threshold_key, old_phrase: seedPhraseList[3], new_phrase: seedPhraseList[4]);

        
        seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult[0].seedPhrase, seedPhraseList[4])
    }
    
    func testMetadata() async {
        await metadata(true);
        await metadata(false);
    }

    func metadata(_ mode: Bool) async {
        let key1 = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)

        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)
        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold_key.reconstruct()
        let metadata = try! threshold_key.get_metadata()
        
        // test metadata related functions here, execution with no error
        let json = try! metadata.export()
        XCTAssertGreaterThan(json.lengthOfBytes(using: .utf8), 0)
        _ = try! Metadata.init(json: json)
        _ = try! threshold_key.get_local_metadata_transitions()
        _ = try! threshold_key.get_last_fetched_cloud_metadata()
    }
    
    func testShareSerializationModule() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_details = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details.total_shares, 2)
        // share serialization with private key, test with mnemonic format
        let phrase = try! ShareSerializationModule.serialize_share(threshold_key: threshold_key, share: key1.hex, format: "mnemonic")
        let key2 = try! ShareSerializationModule.deserialize_share(threshold_key: threshold_key, share: phrase, format: "mnemonic")
        XCTAssertEqual(key1.hex, key2)
        
        // share serialization with share, test with nil type format
        let share = try! await threshold_key.generate_new_share()
        let phrase2 = try! ShareSerializationModule.serialize_share(threshold_key: threshold_key, share: share.hex, format: nil)
        let key3 = try! ShareSerializationModule.deserialize_share(threshold_key: threshold_key, share: phrase2, format: nil)
        XCTAssertEqual(share.hex, key3)
    }
}
