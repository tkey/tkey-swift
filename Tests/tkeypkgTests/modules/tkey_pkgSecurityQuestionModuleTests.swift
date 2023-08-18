import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgSecurityQuestionModuleTests: XCTestCase {
    private var threshold_key: ThresholdKey!

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
        threshold_key = threshold
    }

    override func tearDown() {
        threshold_key = nil
    }

    func test() async {
        let key_reconstruction_details = try! await threshold_key.reconstruct()
        let question = "favorite marvel character"
        let answer = "iron man"
        let answer_2 = "captain america"
        let new_share = try! await SecurityQuestionModule.generate_new_share(thresholdKey: threshold_key, questions: question, answer: answer)
        let share_index = new_share.hex
        let sq_question = try! SecurityQuestionModule.get_questions(threshold_key: threshold_key)
        XCTAssertEqual(sq_question, question)
        var security_input: Bool = try! await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer)
        XCTAssertEqual(security_input, true)
        security_input = try! await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: "ant man")
        XCTAssertEqual(security_input, false)
        let change_answer_result = try! await SecurityQuestionModule.change_question_and_answer(threshold_key: threshold_key, questions: question, answer: answer_2)
        XCTAssertEqual(change_answer_result, true)
        security_input = try! await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer_2)
        XCTAssertEqual(security_input, true)
        let get_answer = try! SecurityQuestionModule.get_answer(threshold_key: threshold_key)
        XCTAssertEqual(get_answer, answer_2)
        _ = try! await SecurityQuestionModule.store_answer(threshold_key: threshold_key, answer: answer_2)
        let key_reconstruction_details_2 = try! await threshold_key.reconstruct()
        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details_2.key)
        try! await threshold_key.delete_share(share_index: share_index)
        security_input = try! await SecurityQuestionModule.input_share(threshold_key: threshold_key, answer: answer)
        XCTAssertEqual(security_input, false)
        let tkey_store = try! threshold_key.get_tkey_store(moduleName: "securityQuestions")
        let id = tkey_store[0]["id"] as! String
        let item = try! threshold_key.get_tkey_store_item(moduleName: "securityQuestions", id: id)["answer"] as! String
        XCTAssertEqual(answer_2, item)
    }
}
