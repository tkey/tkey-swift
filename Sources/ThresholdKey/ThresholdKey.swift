//
//  ThresholdKey.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public class ThresholdKey {
    private(set) var pointer: OpaquePointer?
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
    internal let tkeyQueue = DispatchQueue(label: "thresholdkey.queue")
    
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    public init(metadata: Metadata? = nil, shares: ShareStorePolyIdIndexMap? = nil, storage_layer: StorageLayer, service_provider: ServiceProvider? = nil, local_matadata_transitions: LocalMetadataTransitions? = nil, last_fetch_cloud_metadata: Metadata? = nil, enable_logging: Bool, manual_sync: Bool) throws {
        var errorCode: Int32 = -1
        var providerPointer: OpaquePointer?
        if case .some(let provider) = service_provider {
            providerPointer = provider.pointer
        }
        
        var sharesPointer: OpaquePointer?
        var metadataPointer: OpaquePointer?
        var cloudMetadataPointer: OpaquePointer?
        var transitionsPointer: OpaquePointer?
        
        if shares != nil {
            sharesPointer = shares!.pointer
        }
        
        if metadata != nil
        {
            metadataPointer = metadata!.pointer
        }
        
        if last_fetch_cloud_metadata != nil
        {
            cloudMetadataPointer = last_fetch_cloud_metadata!.pointer
        }
        
        if local_matadata_transitions != nil
        {
            transitionsPointer = local_matadata_transitions!.pointer
        }
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error -> OpaquePointer in
            return threshold_key(metadataPointer, sharesPointer, storage_layer.pointer, providerPointer, transitionsPointer, cloudMetadataPointer, enable_logging, manual_sync, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey")
        }
        pointer = result
       
    }

    public func get_metadata() throws -> Metadata {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_metadata(pointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_metadata")
        }
        return Metadata.init(pointer: result!)
    }

    internal func initialize(import_share: String = "", input: OpaquePointer? = nil, never_initialize_new_key: Bool, include_local_metadata_transitions: Bool) throws -> KeyDetails {
        var errorCode: Int32 = -1
        var sharePointer: UnsafeMutablePointer<Int8>?
        if !import_share.isEmpty {
            sharePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: import_share).utf8String)
        }

        let curvePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: curveN).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_initialize(pointer, sharePointer, input, never_initialize_new_key, include_local_metadata_transitions, curvePointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey Initialize")
        }
        return try! KeyDetails(pointer: result!)
    }
    
    internal func initialize(import_share: String = "", input: OpaquePointer? = nil, never_initialize_new_key: Bool, include_local_metadata_transitions: Bool, completion: @escaping (Result<KeyDetails, Error>) -> Void ) {
        tkeyQueue.async {
            do {
                let result = try self.initialize(import_share: import_share, input: input, never_initialize_new_key: never_initialize_new_key, include_local_metadata_transitions: include_local_metadata_transitions)
                completion(.success(result))
            }catch {
                completion(.failure(error))
            }
        }
    }
    
    public func initialize(import_share: String = "", input: OpaquePointer? = nil, never_initialize_new_key: Bool, include_local_metadata_transitions: Bool) async throws -> KeyDetails {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.initialize(import_share: import_share, input: input, never_initialize_new_key: never_initialize_new_key, include_local_metadata_transitions: include_local_metadata_transitions) {
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
    
    internal func reconstruct() throws -> KeyReconstructionDetails {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_reconstruct(pointer, curvePointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey Reconstruct")
        }
        return try! KeyReconstructionDetails(pointer: result!)
    }
    
    internal func reconstruct(completion: @escaping (Result<KeyReconstructionDetails, Error>) -> Void) {
        tkeyQueue.async {
            do {
                let result = try self.reconstruct()
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func reconstruct() async throws -> KeyReconstructionDetails {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.reconstruct() {
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

    public func reconstruct_latest_poly() throws -> Polynomial {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_reconstruct_latest_poly(pointer, curvePointer,error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in getPublicPolynomial")
        }
        return Polynomial(pointer: result!)
    }
    
    internal func reconstruct_latest_poly(completion: @escaping (Result<Polynomial, Error>) -> Void) {
        tkeyQueue.async {
            do {
                let result = try self.reconstruct_latest_poly()
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func reconstruct_latest_poly() async throws -> Polynomial {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.reconstruct_latest_poly() {
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
    
    public func get_all_share_stores_for_latest_polynomial() throws -> ShareStoreArray {
        var errorCode: Int32 = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_all_share_stores_for_latest_polynomial(pointer, curvePointer,error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_all_share_stores_for_latest_polynomial")
        }
        return try! ShareStoreArray.init(pointer: result!);
    }
    
    internal func generate_new_share() throws -> GenerateShareStoreResult {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_generate_share(pointer, curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey generate_new_share")
        }

        let resultShare = try GenerateShareStoreResult( pointer: result!)
        return resultShare
    }
    
    
    internal func generate_new_share(completion: @escaping (Result<GenerateShareStoreResult, Error>) -> Void) {
        tkeyQueue.async {
            do {
                let result = try self.generate_new_share()
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func generate_new_share() async throws -> GenerateShareStoreResult {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.generate_new_share() {
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

    public func delete_share(share_index: String) throws {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let shareIndexPointer = UnsafeMutablePointer<Int8>(mutating: (share_index as NSString).utf8String)
        withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_delete_share(pointer, shareIndexPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Threshold while Deleting share")
        }
    }
    
    internal func delete_share(share_index: String, completion: @escaping (Result<Void,Error>) -> Void)  {
        tkeyQueue.async {
            do {
                try self.delete_share( share_index: share_index )
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func delete_share(share_index: String) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.delete_share( share_index: share_index ) {
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
    
    public func get_key_details() throws -> KeyDetails {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_get_key_details(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Threshold while Getting Key Details")
        }
        return try! KeyDetails(pointer: result!)
    }

    public func output_share( shareIndex: String, shareType: String?) throws -> String {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let cShareIndex = UnsafeMutablePointer<Int8>(mutating: (shareIndex as NSString).utf8String)

        var cShareType: UnsafeMutablePointer<Int8>?
        if shareType != nil {
            cShareType = UnsafeMutablePointer<Int8>(mutating: (shareType! as NSString).utf8String)
        }
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_output_share(pointer, cShareIndex, cShareType, curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey output_share")
        }
        return String.init(cString: result!)
    }

    public func share_to_share_store(share: String) throws -> ShareStore {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let sharePointer = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_share_to_share_store(pointer, sharePointer, curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey share_to_share_store")
        }
        return ShareStore.init(pointer: result!)
    }

    internal func input_share( share: String, shareType: String?) throws {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let cShare = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)

        var cShareType: UnsafeMutablePointer<Int8>?
        if shareType != nil {
            cShareType = UnsafeMutablePointer<Int8>(mutating: (shareType! as NSString).utf8String)
        }
        withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_input_share(pointer, cShare, cShareType, curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey generate_new_share")
        }
    }
    
    internal func input_share( share: String, shareType: String?, completion: @escaping (Result<Void,Error>) -> Void)  {
        tkeyQueue.async {
            do {
                try self.input_share(share: share, shareType: shareType)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func input_share (share: String, shareType: String?) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.input_share(share: share, shareType: shareType) {
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

    public func output_share_store( shareIndex: String, polyId: String?) throws -> ShareStore {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let cShareIndex = UnsafeMutablePointer<Int8>(mutating: (shareIndex as NSString).utf8String)

        var cPolyId: UnsafeMutablePointer<Int8>?
        if let polyId = polyId {
            cPolyId = UnsafeMutablePointer<Int8>(mutating: (polyId as NSString).utf8String)
        }
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_output_share_store(pointer, cShareIndex, cPolyId, curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey output share store")
        }
        return ShareStore(pointer: result!)
    }

    internal func input_share_store(shareStore: ShareStore) throws {
        var errorCode: Int32  = -1
        withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_input_share_store(pointer, shareStore.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey input share store")
        }
    }
    internal func input_share_store(shareStore: ShareStore, completion: @escaping (Result<Void,Error>) -> Void)  {
        tkeyQueue.async {
            do {
                try self.input_share_store(shareStore: shareStore)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func input_share_store(shareStore: ShareStore) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.input_share_store(shareStore: shareStore) {
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


    public func get_shares_indexes() throws -> [String] {
        var errorCode: Int32  = -1
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_get_shares_indexes(pointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey generate_new_share")
        }

        let string = String.init(cString: result!)
        let indexes = try! JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [String]
        string_free(result)
        return indexes
    }
    
    public func encrypt(msg: String) throws -> String {
        var errorCode: Int32  = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let msgPointer = UnsafeMutablePointer<Int8>(mutating: (msg as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_encrypt(pointer, msgPointer, curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey encrypt")
        }
        return String.init(cString: result!)
    }
    
    public func decrypt(msg: String) throws -> String {
        var errorCode: Int32  = -1
        let msgPointer = UnsafeMutablePointer<Int8>(mutating: (msg as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_decrypt(pointer, msgPointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey decrypt")
        }
        return String.init(cString: result!)
    }
    
    public func get_last_fetched_cloud_metadata() throws -> Metadata {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_last_fetched_cloud_metadata(pointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_last_fetched_cloud_metadata")
        }
        return Metadata.init(pointer: result)
    }
    
    public func get_local_metadata_transitions() throws ->LocalMetadataTransitions {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_local_metadata_transitions(pointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_local_metadata_transitions")
        }
        return LocalMetadataTransitions.init(pointer: result!)
    }
    
    public func get_tkey_store(moduleName: String) throws -> String  {
        var errorCode: Int32  = -1
        
        let modulePointer = UnsafeMutablePointer<Int8>(mutating: (moduleName as NSString).utf8String)
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_get_tkey_store(pointer, modulePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_tkey_store")
        }

        return String.init(cString: result!)
    }
    
    public func get_tkey_store_item(moduleName: String, id: String) throws -> String {
        var errorCode: Int32  = -1
        let modulePointer = UnsafeMutablePointer<Int8>(mutating: (moduleName as NSString).utf8String)
        
        let idPointer = UnsafeMutablePointer<Int8>(mutating: (id as NSString).utf8String)
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_get_tkey_store_item(pointer, modulePointer, idPointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_tkey_store_item")
        }
        return String.init(cString: result!)
    }
    
    internal func sync_local_metadata_transistions() throws {
        var errorCode: Int32  = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: curveN).utf8String)
        
        withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_sync_local_metadata_transitions(pointer, curvePointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey sync_local_metadata_transistions")
        }
    }
    
    internal func sync_local_metadata_transistions(completion: @escaping (Result<Void,Error>) -> Void)  {
        tkeyQueue.async {
            do {
                try self.sync_local_metadata_transistions()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func sync_local_metadata_transistions() async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.sync_local_metadata_transistions() {
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

    deinit {
        threshold_key_free(pointer)
    }
}
