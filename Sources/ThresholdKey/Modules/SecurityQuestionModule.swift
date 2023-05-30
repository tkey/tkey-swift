import Foundation
#if canImport(lib)
    import lib
#endif

public final class SecurityQuestionModule {
    
    private static func generate_new_share(threshold_key: ThresholdKey, questions: String, answer: String, completion: @escaping (Result<GenerateShareStoreResult, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let questionsPointer = UnsafeMutablePointer<Int8>(mutating: (questions as NSString).utf8String)
                let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
                let ptr = withUnsafeMutablePointer(to: &errorCode, { error in
                    security_question_generate_new_share(threshold_key.pointer, questionsPointer, answerPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in SecurityQuestionModule, generate_new_share")
                    }
                let result = try! GenerateShareStoreResult.init(pointer: ptr!)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Generates a new security share on an existing `ThresholdKey` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - question: The security question.
    ///   - answer: The answer for the security question.
    ///
    /// - Returns: `GenerateShareStoreResult` object.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func generate_new_share(threshold_key: ThresholdKey, questions: String, answer: String ) async throws -> GenerateShareStoreResult {
        return try await withCheckedThrowingContinuation {
            continuation in
            generate_new_share(threshold_key: threshold_key, questions: questions, answer: answer) {
                result in
                switch result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private static func input_share(threshold_key: ThresholdKey, answer: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    security_question_input_share(threshold_key.pointer, answerPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    if errorCode == 2103 || errorCode == 2101 {
                        return completion(.success(result))
                    }
                    throw RuntimeError("Error in SecurityQuestionModule, input_share")
                    }
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Inputs a stored security share into an existing `ThresholdKey` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - answer: The answer for the security question of the stored share.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func input_share(threshold_key: ThresholdKey, answer: String ) async throws -> Bool {
        return try await withCheckedThrowingContinuation {
            continuation in
            input_share(threshold_key: threshold_key, answer: answer) {
                result in
                switch result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private static func change_question_and_answer(threshold_key: ThresholdKey, questions: String, answer: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
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
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Changes the question and answer for an existing security share on a `ThresholdKey` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - question: The security question.
    ///   - answer: The answer for the security question.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func change_question_and_answer(threshold_key: ThresholdKey, questions: String, answer: String ) async throws -> Bool {
        return try await withCheckedThrowingContinuation {
            continuation in
            change_question_and_answer(threshold_key: threshold_key, questions: questions, answer: answer) {
                result in
                switch result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    
    private static func store_answer(threshold_key: ThresholdKey, answer: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let answerPointer = UnsafeMutablePointer<Int8>(mutating: (answer as NSString).utf8String)
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    security_question_store_answer(threshold_key.pointer, answerPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in SecurityQuestionModule, store_answer")
                    }
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Saves the answer for an existing security share on a `ThresholdKey` object to the tkey store.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - answer: The answer for the security question.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func store_answer(threshold_key: ThresholdKey, answer: String ) async throws -> Bool {
        return try await withCheckedThrowingContinuation {
            continuation in
            store_answer(threshold_key: threshold_key, answer: answer) {
                result in
                switch result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Retrieves the answer for an existing security share on a `ThresholdKey`.
    /// - Returns: `String`.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func get_answer(threshold_key: ThresholdKey) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_get_answer(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, get_answer")
            }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }

    /// Retrieves the question for an existing security share on a `ThresholdKey`.
    /// - Returns: `String`.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func get_questions(threshold_key: ThresholdKey) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            security_question_get_questions(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SecurityQuestionModule, get_questions")
            }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
}
