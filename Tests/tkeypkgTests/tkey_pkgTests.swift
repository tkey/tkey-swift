import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgTests: XCTestCase {
    func testLibraryVersion() {
        _ = try! library_version()
    }

    func testGenerateDeleteShare() {
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

        let new_share = try! threshold_key.generate_new_share()
        let share_index = new_share.hex

        let key_details_2 = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details_2.total_shares, 3)

        _ = try! threshold_key.output_share(shareIndex: share_index, shareType: nil)

        try! threshold_key.delete_share(share_index: share_index)
        let key_details_3 = try! threshold_key.get_key_details()
        XCTAssertEqual(key_details_3.total_shares, 2)

        XCTAssertThrowsError(
            try threshold_key.output_share(shareIndex: share_index, shareType: nil)
        )

    }

    func testThresholdInputOutputShare() {
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

        let shareStore = try! threshold_key.generate_new_share()

        let shareOut = try! threshold_key.output_share(shareIndex: shareStore.hex, shareType: nil)

        let threshold_key2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)

        _ = try! threshold_key2.initialize(never_initialize_new_key: true, include_local_metadata_transitions: false)

        try! threshold_key2.input_share(share: shareOut, shareType: nil)

        let key2_reconstruction_details = try! threshold_key2.reconstruct()
        XCTAssertEqual( key_reconstruction_details.key, key2_reconstruction_details.key)
    }

    func testSecurityQuestionModule() {
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

        let question = "favorite marvel character"
        let answer = "iron man"
        let answer_2 = "captain america"

        // generate new security share
        let new_share = try! SecurityQuestionModule.generate_new_share(threshold_key: threshold_key, questions: question, answer: answer)
        let share_index = new_share.hex

        let sq_question = try! SecurityQuestionModule.get_questions(threshold_key: threshold_key)
        XCTAssertEqual(sq_question, question)

        let security_input_share: Bool = try! SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer)
        XCTAssertEqual(security_input_share, true)

       XCTAssertThrowsError(try SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: "ant man")
            )

        // change answer for already existing question
        let change_answer_result = try! SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer_2)
        XCTAssertEqual(change_answer_result, true)

        XCTAssertThrowsError(try SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer))

        let security_input_share_2 = try! SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer_2)
        XCTAssertEqual(security_input_share_2, true)

        let get_answer = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual(get_answer, answer_2)

        let key_reconstruction_details_2 = try! threshold_key.reconstruct()
        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details_2.key)

        // delete newly security share
        try! threshold_key.delete_share(share_index: share_index)

        XCTAssertThrowsError(try SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer))
    }

    func testThresholdShareTransfer () {
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

        let request_enc = try! ShareTransferModule.request_new_share(threshold_key: threshold_key2, user_agent: "agent", available_share_indexes: "[]")

        let lookup = try! ShareTransferModule.look_for_request(threshold_key: threshold_key)
        let encPubKey = lookup[0]
        let newShare = try! threshold_key.generate_new_share()

        try! ShareTransferModule.approve_request_with_share_index(threshold_key: threshold_key, enc_pub_key_x: encPubKey, share_index: newShare.hex)

        _ = try! ShareTransferModule.request_status_check(threshold_key: threshold_key2, enc_pub_key_x: request_enc, delete_request_on_completion: true)

        let key_reconstruction_details_2 = try! threshold_key2.reconstruct()

        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details_2.key)
    }

    func testPrivateKeyModule() {
        let key1 = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
        )

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! threshold_key.reconstruct()

        let result = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result.count, 0)

        let key_module = try! PrivateKey.generate()
        let key_module2 = try! PrivateKey.generate()
        // Done setup
        // Try set and get privatekey from privatekey module
        _ = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key:     key_module.hex, format: "secp256k1n")
        let result_1 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result_1, [key_module.hex] )

        // Try set 2nd privatekey
        _ = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: key_module2.hex, format: "secp256k1n")
        let result_2 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result_2, [key_module.hex, key_module2.hex])

        // Try set privateKey module with nil key
        _ = try! PrivateKeysModule.set_private_key(threshold_key: threshold_key, key: nil, format: "secp256k1n")
        let result_3 = try! PrivateKeysModule.get_private_key_accounts(threshold_key: threshold_key)
        XCTAssertEqual(result_3.count, 3)

        // try PrivateKeysModule.remove_private_key()
        // Reconstruct on second instance and check value ?

    }

    func testPolyModule() {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)
        
        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        
        let poly = try! threshold_key.reconstruct_latest_poly()
        
        let pub_poly = try! poly.getPublicPolynomial();
        let threshold_count = try! pub_poly.getThreshold();
        XCTAssertEqual(threshold_count, 2 );
        
        // get all share store
        let share_store = try! threshold_key.get_all_share_stores_for_latest_polynomial();
        XCTAssertEqual(share_store.count, 2 );
        
        let share_index: String = "[4,6,12]";
        let share_map = try! poly.generateShares(share_index: share_index);
        var points_arr: [KeyPoint] = [];
        XCTAssertEqual(share_map.share_map.count, 3 );
        for item in share_map.share_map {
            let share_index = item.key;
            let share = item.value;
            let poly_point = try! KeyPoint(x: share_index, y: share);
            points_arr.append(poly_point);
            
            let point = try! pub_poly.polyCommitmentEval(index: item.key);
            XCTAssertNotNil(point.x);
            XCTAssertNotNil(point.y);
        }
        
        // lagrange interpolation
        let poly_lagrange = try! Lagrange.lagrange(points_arr: points_arr);

        let share_index_1: String = "[5,9,15]";
        let share_map_1 = try! poly_lagrange.generateShares(share_index: share_index_1);
        XCTAssertEqual(share_map_1.share_map.count, 3 );
        
    }

    func testSeedPhraseModule() {
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let key1 = try! PrivateKey.generate()
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
            )

        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! threshold_key.reconstruct()
        let seedPhraseToSet = "seed sock milk update focus rotate barely fade car face mechanic mercy"
        let seedPhraseToSet2 = "object brass success calm lizard science syrup planet exercise parade honey impulse"

//        Check the seedphrase module is empty
        let seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 0 )

//        set and get seedphrases
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet, number_of_wallets: 0)
        let seedResult_2 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_2[0].seedPhrase, seedPhraseToSet )

//        Try delete unknown seedphrase - expect fail
        XCTAssertThrowsError(try SeedPhraseModule.delete_seedphrase(threshold_key: threshold_key, phrase: seedPhraseToSet2))

//        Try to set and get 2nd seedphrases
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet2, number_of_wallets: 0)
        let seedResult_3 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_3[0].seedPhrase, seedPhraseToSet )
        XCTAssertEqual(seedResult_3[1].seedPhrase, seedPhraseToSet2 )

//        Try set seedphrase with existing seed phrase
        XCTAssertThrowsError(try SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet2, number_of_wallets: 0))

//        Try set seedphrase with nil
        try! SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: nil, number_of_wallets: 0)
        let seedResult_4 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_4.count, 3 )

//        Try reconstruct 2nd Tkey instance to check if seed phrase is persistance
    }

    func test_get_metadata() {
        let key1 = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)

        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: key1.hex)
        let threshold_key = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false)
        _ = try! threshold_key.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false)
        _ = try! threshold_key.reconstruct()
        let metadata = try! threshold_key.get_metadata()
        let json = try! metadata.export()
        XCTAssertGreaterThan(json.lengthOfBytes(using: .utf8), 0)
        _ = try! Metadata.init(json: json)
    }
}
