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
        await generateDeleteShare(false);
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
                async let new_share = try! SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: "hello", answer: "bye");
                async let new_share2 = try! threshold_key.generate_new_share()
                async let new_share3 = try! threshold_key.generate_new_share()
                async let new_share4 = try! threshold_key.generate_new_share()
                let key_details_2 = try! threshold_key.get_key_details()
                return key_details_2.total_shares
        }.value
        
            
        // create one more new shares
        let new_share = try! await threshold_key.generate_new_share()
//        let key_details_2 = try! threshold_key.get_key_details()
        let share_index = new_share.hex;
            
        // await for previous promise to resolve
        let numberofshares = await create4share;
        
        // create4share was executed before shares were generated
        // Its possible that the following line will fail randomly. if it does, please inform CW
        XCTAssertEqual(numberofshares, 2)

        _ = try! threshold_key.output_share(shareIndex: share_index, shareType: nil)
        try! await threshold_key.delete_share(share_index: share_index)
        let key_details_3 = try! threshold_key.get_key_details()
        
        XCTAssertEqual(key_details_3.total_shares, 6)
        do {
            let _ = try threshold_key.output_share(shareIndex: share_index, shareType: nil)
            XCTAssertTrue( false )
        }catch {
         // Should throw error
        }
        
    }

    func testThresholdInputOutputShare() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_reconstruction_details = try! await threshold_key.reconstruct()

        let shareStore = try! await threshold_key.generate_new_share()

        let shareOut = try! threshold_key.output_share(shareIndex: shareStore.hex, shareType: nil)

        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! await threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false)

        try! await threshold_key2.input_share(share: shareOut, shareType: nil)

        let key2_reconstruction_details = try! await threshold_key2.reconstruct()
        XCTAssertEqual( key_reconstruction_details.key, key2_reconstruction_details.key)
    }

    func testSecurityQuestionModule() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_reconstruction_details = try! await threshold_key.reconstruct()

        let question = "favorite marvel character"
        let answer = "iron man"
        let answer_2 = "captain america"

        // generate new security share
        // TODO: convert the following into a task. This will guarantee that async fns are executed in order using tkeyQueue.
        let new_share = try! await SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question, answer: answer)
        let share_index = new_share.hex

        let sq_question = try! SecurityQuestionModule.get_questions(threshold_key: threshold_key)
        XCTAssertEqual(sq_question, question)

        let security_input_share: Bool = try! await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer)
        XCTAssertEqual(security_input_share, true)

        do {
            let result_1 = try await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: "ant man")
            XCTAssertTrue( false )
        } catch {
            
        }
            
        
        // change answer for already existing question
        let change_answer_result = try! await SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer_2)
        XCTAssertEqual(change_answer_result, true)

        do {
            let result_2 = try await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer)
            XCTAssertTrue( false )
        }catch {
        }
        
        let security_input_share_2 = try! await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer_2)
        XCTAssertEqual(security_input_share_2, true)

        let get_answer = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual(get_answer, answer_2)

        let key_reconstruction_details_2 = try! await threshold_key.reconstruct()
        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details_2.key)

        // delete newly security share
        try! await threshold_key.delete_share(share_index: share_index)

        do {
            let result_3 = try await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer)
            XCTAssertTrue( false )
        }catch{}
    }

    func testThresholdShareTransfer () async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)

        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        let key_reconstruction_details = try! await threshold_key.reconstruct()

        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! await threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false)
        
        // TODO: convert the following into a task. This will guarantee that async fns are executed in order using tkeyQueue.
        // Application would want to request a new share and wait for it as a task (potentially)
        let request_enc = try! await ShareTransferModule.request_new_share(threshold_key: threshold_key2, user_agent: "agent", available_share_indexes: "[]")

        let lookup = try! await ShareTransferModule.look_for_request(threshold_key: threshold_key)
        let encPubKey = lookup[0]
        let newShare = try! await threshold_key.generate_new_share()

        try! await ShareTransferModule.approve_request_with_share_index(threshold_key: threshold_key, enc_pub_key_x: encPubKey, share_index: newShare.hex)

        _ = try! await ShareTransferModule.request_status_check(threshold_key: threshold_key2, enc_pub_key_x: request_enc, delete_request_on_completion: true)

        let key_reconstruction_details_2 = try! await threshold_key2.reconstruct()

        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details_2.key)
    }

    func testPrivateKeyModule() async {
        let key1 = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
        )

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold_key.reconstruct()

        let result = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result.count, 0)

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

    func testPolynomialModule() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)
        
        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        
        let poly = try! await threshold_key.reconstruct_latest_poly()
        
        let pub_poly = try! poly.getPublicPolynomial();
        let threshold_count = try! pub_poly.getThreshold();
        XCTAssertEqual(threshold_count, 2 );
        
        // get all share store
        let share_store = try! threshold_key.get_all_share_stores_for_latest_polynomial();
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
        
        let lagrange_poly = try! Lagrange.lagrange(points: points_arr);
        XCTAssertNotNil(lagrange_poly);
    }

    func testSeedPhraseModule() async {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
            )

        _ = try! await threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! await threshold_key.reconstruct()
        let seedPhraseToSet = "seed sock milk update focus rotate barely fade car face mechanic mercy"
        let seedPhraseToSet2 = "object brass success calm lizard science syrup planet exercise parade honey impulse"
        
        // TODO: convert the following into a task. This will guarantee that async fns are executed in order using tkeyQueue.

        
//        Check the seedphrase module is empty
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

    func test_get_metadata() async {
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
        let json = try! metadata.export()
        XCTAssertGreaterThan(json.lengthOfBytes(using: .utf8), 0)
        _ = try! Metadata.init(json: json)
    }
}
