import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareTransferModule {
    /// This module facilitates the transfer of shares between devices, this ensure that both devies can share the same private key. The service provider configuration will need to be the same for both instances of the `ThresholdKey`. This is particularly useful where a user would want to share a login between multiple devices that they control without ending up with a common share between them after the process is complete.
    /// Device A will fully reconstruct the `ThresholdKey`.
    /// Device B will be initialized in the same way as Device A.
    /// Device B will request a share from Device A.
    /// Device A will then lookup and approve the share request for Device B.
    /// Device B would then check the status of the request until it is approved.
    /// Device B would then be able to reconstruct the `ThresholdKey`, reaching the same private key as Device A.
    /// Device B would then cleanup the share request, automatic if enabled.
    
    private static func request_new_share(threshold_key: ThresholdKey, user_agent: String, available_share_indexes: String, completion: @escaping (Result<String, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let agentPointer = UnsafeMutablePointer<Int8>(mutating: (user_agent as NSString).utf8String)
                let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (available_share_indexes as NSString).utf8String)
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_request_new_share(threshold_key.pointer, agentPointer, indexesPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, request share. Error Code: \(errorCode)")
                    }
                let string = String.init(cString: result!)
                string_free(result)
                completion(.success(string))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Requests a new share for transfer for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - user_agent: `String` containing information about the device requesting the share.
    ///   - available_share_indexes: Json represented as a `String` indicating the available share indexes on which the transfer should take place, can be an empty array `"[]"`
    ///
    /// - Returns: `String`, the encryption key.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func request_new_share(threshold_key: ThresholdKey, user_agent: String, available_share_indexes: String ) async throws -> String {
        return try await withCheckedThrowingContinuation {
            continuation in
            request_new_share(threshold_key: threshold_key, user_agent: user_agent, available_share_indexes: available_share_indexes) {
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
    
    private static func add_custom_info_to_request(threshold_key: ThresholdKey, enc_pub_key_x: String, custom_info: String, completion: @escaping (Result<Void, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
                let customPointer = UnsafeMutablePointer<Int8>(mutating: (custom_info as NSString).utf8String)
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_add_custom_info_to_request(threshold_key.pointer, encPointer, customPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, add custom info to request. Error Code: \(errorCode)")
                    }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Adds custom information to a share transfer request for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - enc_pub_key_x: The encryption key for the share transfer request.
    ///   - custom_info: Json represented as a `String`, the custom information to be added.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func add_custom_info_to_request(threshold_key: ThresholdKey, enc_pub_key_x: String, custom_info: String ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            add_custom_info_to_request(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x, custom_info: custom_info) {
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
    
    private static func look_for_request(threshold_key: ThresholdKey, completion: @escaping (Result<[String], Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_look_for_request(threshold_key.pointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, lookup for request. Error Code: \(errorCode)")
                    }
                let string = String.init(cString: result!)
                let indicator_array = try! JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [String]
                string_free(result)
                completion(.success(indicator_array))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Searches for available share transfer requests for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///
    /// - Returns: Array of `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func look_for_request(threshold_key: ThresholdKey ) async throws -> [String] {
        return try await withCheckedThrowingContinuation {
            continuation in
            look_for_request(threshold_key: threshold_key) {
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
    
    
    private static func approve_request(threshold_key: ThresholdKey, enc_pub_key_x: String, share_store: ShareStore, completion: @escaping (Result<Void, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_approve_request(threshold_key.pointer, encPointer, share_store.pointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, change_question_and_answer. Error Code: \(errorCode)")
                    }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Approves a share transfer request for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - enc_pub_key_x: The encryption key for the share transfer request.
    ///   - share_store: The `ShareStore` for the share transfer request.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func approve_request(threshold_key: ThresholdKey, enc_pub_key_x: String, share_store: ShareStore ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            approve_request(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x, share_store: share_store) {
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

    private static func approve_request_with_share_index(threshold_key: ThresholdKey, enc_pub_key_x: String, share_index: String, completion: @escaping (Result<Void, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
                let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (share_index as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_approve_request_with_share_indexes(threshold_key.pointer, encPointer, indexesPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, approve request with share index. Error Code: \(errorCode)")
                    }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Approves a share transfer request for a specific share index for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - enc_pub_key_x: The encryption key for the share transfer request.
    ///   - share_index: The relevant share index for the share transfer request.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func approve_request_with_share_index(threshold_key: ThresholdKey, enc_pub_key_x: String, share_index: String ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            approve_request_with_share_index(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x, share_index: share_index) {
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

    private static func get_store(threshold_key: ThresholdKey, completion: @escaping (Result<ShareTransferStore, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let ptr = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_get_store(threshold_key.pointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, get store. Error Code: \(errorCode)")
                    }
                let result = ShareTransferStore.init(pointer: ptr!)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Retrieves the share transfer store for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///
    /// - Returns: `ShareTransferStore`
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func get_store(threshold_key: ThresholdKey ) async throws -> ShareTransferStore {
        return try await withCheckedThrowingContinuation {
            continuation in
            get_store(threshold_key: threshold_key) {
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

    private static func set_store(threshold_key: ThresholdKey, store: ShareTransferStore, completion: @escaping (Result<Bool, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_set_store(threshold_key.pointer, store.pointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, set store. Error Code: \(errorCode)")
                    }
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Sets the share transfer store for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func set_store(threshold_key: ThresholdKey, store: ShareTransferStore ) async throws -> Bool {
        return try await withCheckedThrowingContinuation {
            continuation in
            set_store(threshold_key: threshold_key, store: store ) {
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

    
    private static func delete_store(threshold_key: ThresholdKey, enc_pub_key_x: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_delete_store(threshold_key.pointer, encPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, delete store. Error Code: \(errorCode)")
                    }
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Removes the share transfer store for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - enc_pub_key_x: The encryption key for the share transfer request.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func delete_store(threshold_key: ThresholdKey, enc_pub_key_x: String ) async throws -> Bool {
        return try await withCheckedThrowingContinuation {
            continuation in
            delete_store(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x) {
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
    
    /// Retrieves the encryption key for the current share transfer request of a  `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func get_current_encryption_key(threshold_key: ThresholdKey) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_get_current_encryption_key(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            if errorCode == 6 {
                return ""
            }
            throw RuntimeError("Error in ShareTransferModule, get current encryption key. Error Code: \(errorCode)")
            }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
    
    private static func request_status_check(threshold_key: ThresholdKey, enc_pub_key_x: String, delete_request_on_completion: Bool, completion: @escaping (Result<ShareStore, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
                let ptr = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_request_status_check(threshold_key.pointer, encPointer, delete_request_on_completion, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, request status check. Error Code: \(errorCode)")
                    }
                let result = ShareStore.init(pointer: ptr!)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Checks the status of a share transfer request for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - enc_pub_key_x: The encryption key for the share transfer request.
    ///   - delete_request_on_completion: Determines if the share request should be deleted on completion.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func request_status_check(threshold_key: ThresholdKey, enc_pub_key_x: String, delete_request_on_completion: Bool ) async throws -> ShareStore {
        return try await withCheckedThrowingContinuation {
            continuation in
            request_status_check(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x, delete_request_on_completion: delete_request_on_completion) {
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

    /// Clears share transfer requests for a `Threshold Key` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func cleanup_request(threshold_key: ThresholdKey) throws {
        var errorCode: Int32 = -1
        withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_cleanup_request(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, cleanup request. Error Code: \(errorCode)")
            }
    }
}
