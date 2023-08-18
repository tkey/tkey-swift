import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgSecurityQuestionModuleTests: XCTestCase {
    private var thresholdKey: ThresholdKey!

    override func setUp() async throws {
        let postboxKey = try! PrivateKey.generate()
        let storageLayer = try! StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2)
        let serviceProvider = try! ServiceProvider(enableLogging: true, postboxKey: postboxKey.hex)
        let threshold = try! ThresholdKey(
            storageLayer: storageLayer,
            serviceProvider: serviceProvider,
            enableLogging: true,
            manualSync: false
        )

        _ = try! await threshold.initialize()
        thresholdKey = threshold
    }

    override func tearDown() {
        thresholdKey = nil
    }

    func test() async {
        let key_reconstruction_details = try! await thresholdKey.reconstruct()
        let question = "favorite marvel character"
        let answer = "iron man"
        let answer_2 = "captain america"
        let new_share = try! await SecurityQuestionModule.generate_new_share(thresholdKey: thresholdKey, questions: question, answer: answer)
        let share_index = new_share.hex
        let sq_question = try! SecurityQuestionModule.get_questions(thresholdKey: thresholdKey)
        XCTAssertEqual(sq_question, question)
        var security_input: Bool = try! await SecurityQuestionModule.input_share(thresholdKey: thresholdKey, answer: answer)
        XCTAssertEqual(security_input, true)
        security_input = try! await SecurityQuestionModule.input_share(thresholdKey: thresholdKey, answer: "ant man")
        XCTAssertEqual(security_input, false)
        let change_answer_result = try! await SecurityQuestionModule.change_question_and_answer(thresholdKey: thresholdKey, questions: question, answer: answer_2)
        XCTAssertEqual(change_answer_result, true)
        security_input = try! await SecurityQuestionModule.input_share(thresholdKey: thresholdKey, answer: answer_2)
        XCTAssertEqual(security_input, true)
        let get_answer = try! SecurityQuestionModule.get_answer(thresholdKey: thresholdKey)
        XCTAssertEqual(get_answer, answer_2)
        _ = try! await SecurityQuestionModule.store_answer(thresholdKey: thresholdKey, answer: answer_2)
        let key_reconstruction_details_2 = try! await thresholdKey.reconstruct()
        XCTAssertEqual(key_reconstruction_details.key, key_reconstruction_details_2.key)
        try! await thresholdKey.delete_share(shareIndex: share_index)
        security_input = try! await SecurityQuestionModule.input_share(thresholdKey: thresholdKey, answer: answer)
        XCTAssertEqual(security_input, false)
        let tkey_store = try! thresholdKey.get_tkey_store(moduleName: "securityQuestions")
        let id = tkey_store[0]["id"] as! String
        let item = try! thresholdKey.get_tkey_store_item(moduleName: "securityQuestions", id: id)["answer"] as! String
        XCTAssertEqual(answer_2, item)
    }
}
