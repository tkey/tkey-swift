//
//  SecurityQuestionModule.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public final class SecurityQuestionModule {
    public static func generate_new_share(threshold_key: ThresholdKey, questions: String, answer: String) throws -> GenerateShareStoreResult {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let questionsPointer = UnsafeMutablePointer<Int8>(mutating: (questions as NSString).utf8String)
        let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_generate_new_share(threshold_key.pointer, questionsPointer, answerPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, generate_new_share")
            }
        return try! GenerateShareStoreResult.init(pointer: result!)
    }
    
    public static func generateNewShareAsync(threshold_key: ThresholdKey, questions: String, answer: String, completion: @escaping (Result<KeyDetails, Error>) -> Void) {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let questionsPointer = UnsafeMutablePointer<Int8>(mutating: (questions as NSString).utf8String)
        let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
        
        DispatchQueue.global().async{
            do {
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    security_question_generate_new_share(threshold_key.pointer, questionsPointer, answerPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in SecurityQuestionModule, generate_new_share")
                    }
                let keyDetails = try! KeyDetails(pointer: result!)
                completion(.success(keyDetails))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public static func input_share(threshold_key: ThresholdKey, answer: String) throws -> Bool {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_input_share(threshold_key.pointer, answerPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, input_share")
            }
        return result
    }

    public static func change_question_and_answer(threshold_key: ThresholdKey, questions: String, answer: String) throws -> Bool {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let questionsPointer = UnsafeMutablePointer<Int8>(mutating: (questions as NSString).utf8String)
        let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_change_question_and_answer(threshold_key.pointer, questionsPointer, answerPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, change_question_and_answer")
            }
        return result
    }

    public static func store_answer(threshold_key: ThresholdKey, answer: String) throws -> Bool {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_store_answer(threshold_key.pointer, answerPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, change_question_and_answer")
            }
        return result
    }

    public static func get_answer(threshold_key: ThresholdKey) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_get_answer(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, change_question_and_answer")
            }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }

    public static func get_questions(threshold_key: ThresholdKey) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_get_questions(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, change_question_and_answer")
            }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
}