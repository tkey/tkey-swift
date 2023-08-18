import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareTransferModule {
    /// This module facilitates the transfer of shares between devices, this ensure that both devies can share the same private key.
    /// The service provider configuration will need to be the same for both instances of the `ThresholdKey`. This is particularly useful where
    /// a user would want to share a login between multiple devices that they control without ending up with a common share between them after the process is complete.
    /// Device A will fully reconstruct the `ThresholdKey`.
    /// Device B will be initialized in the same way as Device A.
    /// Device B will request a share from Device A.
    /// Device A will then lookup and approve the share request for Device B.
    /// Device B would then check the status of the request until it is approved.
    /// Device B would then be able to reconstruct the `ThresholdKey`, reaching the same private key as Device A.
    /// Device B would then cleanup the share request, automatic if enabled.

    private static func request_new_share(thresholdkey: ThresholdKey, userAgent: String, availableShareIndexes: String, completion: @escaping (Result<String, Error>) -> Void) {
        thresholdkey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdkey.curveN as NSString).utf8String)
                let agentPointer = UnsafeMutablePointer<Int8>(mutating: (userAgent as NSString).utf8String)
                let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (availableShareIndexes as NSString).utf8String)
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_request_new_share(thresholdkey.pointer, agentPointer, indexesPointer, curvePointer, error)
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
    ///   - thresholdkey: The threshold key to act on.
    ///   - user_agent: `String` containing information about the device requesting the share.
    ///   - availableShareIndexes: Json represented as a `String` indicating the available share indexes on which the transfer should take place, can be an empty array `"[]"`
    ///
    /// - Returns: `String`, the encryption key.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func request_new_share(thresholdkey: ThresholdKey, userAgent: String, availableShareIndexes: String ) async throws -> String {
        return try await withCheckedThrowingContinuation {
            continuation in
            request_new_share(thresholdkey: thresholdkey, userAgent: userAgent, availableShareIndexes: availableShareIndexes) {
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

    private static func add_custom_info_to_request(thresholdkey: ThresholdKey, encPubKeyX: String, customInfo: String, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (encPubKeyX as NSString).utf8String)
                let customPointer = UnsafeMutablePointer<Int8>(mutating: (customInfo as NSString).utf8String)
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdkey.curveN as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_add_custom_info_to_request(thresholdkey.pointer, encPointer, customPointer, curvePointer, error)
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
    ///   - thresholdkey: The threshold key to act on.
    ///   - enc_pub_key_x: The encryption key for the share transfer request.
    ///   - custom_info: Json represented as a `String`, the custom information to be added.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func add_custom_info_to_request(thresholdkey: ThresholdKey, encPubKeyX: String, customInfo: String ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            add_custom_info_to_request(thresholdkey: thresholdKey, enc_pub_key_x: encPubKeyX, custom_info: customInfo) {
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

    private static func look_for_request(thresholdkey: ThresholdKey, completion: @escaping (Result<[String], Error>) -> Void) {
        thresholdkey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_look_for_request(thresholdkey.pointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ShareTransferModule, lookup for request. Error Code: \(errorCode)")
                    }
                let string = String.init(cString: result!)
                let indicatorArray = try JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as [String]
                string_free(result)
                completion(.success(indicatorArray))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Searches for available share transfer requests for a `Threshold Key` object.
    /// - Parameters:
    ///   - thresholdKey: The threshold key to act on.
    ///
    /// - Returns: Array of `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func look_for_request(thresholdkey: ThresholdKey ) async throws -> [String] {
        return try await withCheckedThrowingContinuation {
            continuation in
            look_for_request(thresholdkey: thresholdkey) {
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

    private static func approve_request(thresholdkey: ThresholdKey, encPubKeyX: String, shareStore: ShareStore? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdkey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                var storePointer: OpaquePointer?

                if shareStore != nil {
                    storePointer = shareStore!.pointer
                }
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdkey.curveN as NSString).utf8String)
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (encPubKeyX as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_approve_request(thresholdkey.pointer, encPointer, storePointer, curvePointer, error)
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
    ///   - thresholdkey: The threshold key to act on.
    ///   - enc_pub_key_x: The encryption key for the share transfer request.
    ///   - share_store: The `ShareStore` for the share transfer request, optional.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func approve_request(thresholdkey: ThresholdKey, encPubKeyX: String, shareStore: ShareStore? = nil ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            approve_request(thresholdkey: thresholdkey, encPubKeyX: encPubKeyX, shareStore: shareStore) {
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

    private static func approve_request_with_share_index(thresholdkey: ThresholdKey, encPubKeyX: String, shareIndex: String, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdkey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdkey.curveN as NSString).utf8String)
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (encPubKeyX as NSString).utf8String)
                let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (shareIndex as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_approve_request_with_share_indexes(thresholdkey.pointer, encPointer, indexesPointer, curvePointer, error)
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
    ///   - thresholdkey: The threshold key to act on.
    ///   - enc_pub_key_x: The encryption key for the share transfer request.
    ///   - share_index: The relevant share index for the share transfer request.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func approve_request_with_share_index(thresholdkey: ThresholdKey, encPubKeyX: String, shareIndex: String ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            approve_request_with_share_index(thresholdkey: thresholdkey, encPubKeyX: encPubKeyX, shareIndex: shareIndex) {
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

    private static func get_store(thresholdkey: ThresholdKey, completion: @escaping (Result<ShareTransferStore, Error>) -> Void) {
        thresholdkey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let ptr = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_get_store(thresholdkey.pointer, error)
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
    ///   - thresholdKey: The threshold key to act on.
    ///
    /// - Returns: `ShareTransferStore`
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func get_store(thresholdKey: ThresholdKey ) async throws -> ShareTransferStore {
        return try await withCheckedThrowingContinuation {
            continuation in
            get_store(thresholdKey: thresholdKey) {
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

    private static func set_store(thresholdKey: ThresholdKey, store: ShareTransferStore, completion: @escaping (Result<Bool, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_set_store(thresholdKey.pointer, store.pointer, curvePointer, error)
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
    ///   - thresholdKey: The threshold key to act on.
    ///   - store: The share transfer store.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func set_store(thresholdKey: ThresholdKey, store: ShareTransferStore ) async throws -> Bool {
        return try await withCheckedThrowingContinuation {
            continuation in
            set_store(thresholdKey: thresholdKey, store: store ) {
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

    private static func delete_store(thresholdKey: ThresholdKey, encPubKeyX: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (encPubKeyX as NSString).utf8String)
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_delete_store(thresholdKey.pointer, encPointer, curvePointer, error)
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
    ///   - thresholdKey: The threshold key to act on.
    ///   - encPubKeyX: The encryption key for the share transfer request.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func delete_store(thresholdKey: ThresholdKey, encPubKeyX: String ) async throws -> Bool {
        return try await withCheckedThrowingContinuation {
            continuation in
            delete_store(thresholdKey: thresholdKey, encPubKeyX: encPubKeyX) {
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
    ///   - thresholdKey: The threshold key to act on.
    ///
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func get_current_encryption_key(thresholdKey: ThresholdKey) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_get_current_encryption_key(thresholdKey.pointer, error)
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

    private static func request_status_check(thresholdKey: ThresholdKey, encPubKeyX: String, deleteRequestOnCompletion: Bool,
                                             completion: @escaping (Result<ShareStore, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)
                let encPointer = UnsafeMutablePointer<Int8>(mutating: (encPubKeyX as NSString).utf8String)
                let ptr = withUnsafeMutablePointer(to: &errorCode, { error in
                    share_transfer_request_status_check(thresholdKey.pointer, encPointer, deleteRequestOnCompletion, curvePointer, error)
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
    ///   - thresholdKey: The threshold key to act on.
    ///   - enc_pub_key_x: The encryption key for the share transfer request.
    ///   - delete_request_on_completion: Determines if the share request should be deleted on completion.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func request_status_check(thresholdKey: ThresholdKey, encPubKeyX: String, deleteRequestOnCompletion: Bool ) async throws -> ShareStore {
        return try await withCheckedThrowingContinuation {
            continuation in
            request_status_check(thresholdKey: thresholdKey, encPubKeyX: encPubKeyX, deleteRequestOnCompletion: deleteRequestOnCompletion) {
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
    ///   - thresholdKey: The threshold key to act on.
    ///
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func cleanup_request(thresholdKey: ThresholdKey) throws {
        var errorCode: Int32 = -1
        withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_cleanup_request(thresholdKey.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, cleanup request. Error Code: \(errorCode)")
            }
    }
}
