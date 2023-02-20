//
//  ShareTransferModule.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareTransferModule {
    internal static func request_new_share(threshold_key: ThresholdKey, user_agent: String, available_share_indexes: String) throws -> String {
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
        return string
    }
    
    internal static func request_new_share(threshold_key: ThresholdKey, user_agent: String, available_share_indexes: String, completion: @escaping (Result<String, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                let result = try request_new_share(threshold_key: threshold_key, user_agent: user_agent, available_share_indexes: available_share_indexes)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
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
    
    internal static func add_custom_info_to_request(threshold_key: ThresholdKey, enc_pub_key_x: String, custom_info: String) throws {
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
    }
    
    internal static func add_custom_info_to_request(threshold_key: ThresholdKey, enc_pub_key_x: String, custom_info: String, completion: @escaping (Result<Void, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                try add_custom_info_to_request(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x, custom_info: custom_info)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
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

    internal static func look_for_request(threshold_key: ThresholdKey) throws -> [String] {
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
        return indicator_array
    }
    
    internal static func look_for_request(threshold_key: ThresholdKey, completion: @escaping (Result<[String], Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                let result = try look_for_request(threshold_key: threshold_key)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
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
    
    internal static func approve_request(threshold_key: ThresholdKey, enc_pub_key_x: String, share_store: ShareStore) throws {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
        withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_approve_request(threshold_key.pointer, encPointer, share_store.pointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, change_question_and_answer. Error Code: \(errorCode)")
            }
    }
    
    internal static func approve_request(threshold_key: ThresholdKey, enc_pub_key_x: String, share_store: ShareStore, completion: @escaping (Result<Void, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                try approve_request(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x, share_store: share_store )
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
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

    internal static func approve_request_with_share_index(threshold_key: ThresholdKey, enc_pub_key_x: String, share_index: String) throws {
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
    }

    internal static func approve_request_with_share_index(threshold_key: ThresholdKey, enc_pub_key_x: String, share_index: String, completion: @escaping (Result<Void, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                try approve_request_with_share_index(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x, share_index: share_index )
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
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
    
    internal static func get_store(threshold_key: ThresholdKey) throws -> ShareTransferStore {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_get_store(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, get store. Error Code: \(errorCode)")
            }
        return ShareTransferStore.init(pointer: result!)
    }
    
    
    internal static func get_store(threshold_key: ThresholdKey, completion: @escaping (Result<ShareTransferStore, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                let result = try get_store(threshold_key: threshold_key)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
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

    internal static func set_store(threshold_key: ThresholdKey, store: ShareTransferStore) throws -> Bool {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_set_store(threshold_key.pointer, store.pointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, set store. Error Code: \(errorCode)")
            }
        return result
    }

    internal static func set_store(threshold_key: ThresholdKey, store: ShareTransferStore, completion: @escaping (Result<Bool, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                let result = try set_store(threshold_key: threshold_key, store: store)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
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
    
    internal static func delete_store(threshold_key: ThresholdKey, enc_pub_key_x: String) throws -> Bool {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_delete_store(threshold_key.pointer, encPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, delete store. Error Code: \(errorCode)")
            }
        return result
    }

    
    internal static func delete_store(threshold_key: ThresholdKey, enc_pub_key_x: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                let result = try delete_store(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
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
    
    public static func get_current_encryption_key(threshold_key: ThresholdKey) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_get_current_encryption_key(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, get current encryption key. Error Code: \(errorCode)")
            }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }

    internal static func request_status_check(threshold_key: ThresholdKey, enc_pub_key_x: String, delete_request_on_completion: Bool) throws -> ShareStore {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        let encPointer = UnsafeMutablePointer<Int8>(mutating: (enc_pub_key_x as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_transfer_request_status_check(threshold_key.pointer, encPointer, delete_request_on_completion, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareTransferModule, request status check. Error Code: \(errorCode)")
            }
        return ShareStore.init(pointer: result!)
    }
    
    internal static func request_status_check(threshold_key: ThresholdKey, enc_pub_key_x: String, delete_request_on_completion: Bool, completion: @escaping (Result<ShareStore, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                let result = try request_status_check(threshold_key: threshold_key, enc_pub_key_x: enc_pub_key_x, delete_request_on_completion: delete_request_on_completion)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
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
