import Foundation
#if canImport(lib)
    import lib
#endif
import TorusUtils
import CommonSources

public class ThresholdKey {
    private(set) var pointer: OpaquePointer?
    private(set) var use_tss: Bool = false
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
    internal let tkeyQueue = DispatchQueue(label: "thresholdkey.queue")
    

    /// Instantiate a `ThresholdKey` object,
    ///
    /// - Parameters:
    ///   - metadata: Existing metadata to be used, optional.
    ///   - shares: Existing shares to be used, optional.
    ///   - storage_layer: Storage layer to be used.
    ///   - service_provider: Service provider to be used, optional only in the most basic usage of tKey.
    ///   - local_matadata_transitions: Existing local transitions to be used.
    ///   - last_fetch_cloud_metadata: Existing cloud metadata to be used.
    ///   - enable_logging: Determines whether logging is available or not (pending).
    ///   - manual_sync: Determines if changes to the metadata are automatically synced.
    ///   - rss_comm: RSS client, required for TSS.
    ///
    /// - Returns: `ThresholdKey`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters.
    public init(metadata: Metadata? = nil, shares: ShareStorePolyIdIndexMap? = nil, storage_layer: StorageLayer, service_provider: ServiceProvider? = nil, local_matadata_transitions: LocalMetadataTransitions? = nil, last_fetch_cloud_metadata: Metadata? = nil, enable_logging: Bool, manual_sync: Bool, rss_comm: RssComm? = nil) throws {
        var errorCode: Int32 = -1
        var providerPointer: OpaquePointer?
        if case .some(let provider) = service_provider {
            providerPointer = provider.pointer
        }
        
        var sharesPointer: OpaquePointer?
        var metadataPointer: OpaquePointer?
        var cloudMetadataPointer: OpaquePointer?
        var transitionsPointer: OpaquePointer?
        var rssCommPtr: OpaquePointer?
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
        
        if rss_comm != nil {
            rssCommPtr = rss_comm!.pointer
            use_tss = true
        }
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error -> OpaquePointer in
            return threshold_key(metadataPointer, sharesPointer, storage_layer.pointer, providerPointer, transitionsPointer, cloudMetadataPointer, enable_logging, manual_sync, rssCommPtr, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey")
        }
        
        pointer = result
       
    }
    

    /// Returns the metadata,
    ///
    /// - Returns: `Metadata`
    ///
    /// - Throws: `RuntimeError`, indicates invalid underlying poiner.
    public func get_metadata() throws -> Metadata {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_current_metadata(pointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_metadata")
        }
        return Metadata.init(pointer: result!)
    }
    
    private func initialize(import_share: String?, input: ShareStore?, never_initialize_new_key: Bool?, include_local_metadata_transitions: Bool?,  use_tss: Bool = false, device_tss_share: String?, device_tss_index: Int32?, tss_factor_pub: KeyPoint?, completion: @escaping (Result<KeyDetails, Error>) -> Void ) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                var sharePointer: UnsafeMutablePointer<Int8>?
                var tssDeviceSharePointer: UnsafeMutablePointer<Int8>?
                var tssFactorPubPointer: OpaquePointer?
                var device_index: Int32 = device_tss_index ?? 2
                if import_share != nil {
                    sharePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: import_share!).utf8String)
                }
                
                if device_tss_share != nil {
                    tssDeviceSharePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: device_tss_share!).utf8String)
                }

                if tss_factor_pub != nil {
                    tssFactorPubPointer = tss_factor_pub!.pointer
                }
                
                var storePtr: OpaquePointer?
                if input != nil {
                    storePtr = input!.pointer
                }
                
                let neverInitializeNewKey = never_initialize_new_key ?? false
                let includeLocalMetadataTransitions = include_local_metadata_transitions ?? false
                
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: self.curveN).utf8String)
                let ptr = withUnsafeMutablePointer(to: &device_index, { tssDeviceIndexPointer in withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_initialize(self.pointer, sharePointer, storePtr, neverInitializeNewKey, includeLocalMetadataTransitions, curvePointer, use_tss, tssDeviceSharePointer, tssDeviceIndexPointer, tssFactorPubPointer, error)})})
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey Initialize")
                }
                let result = try! KeyDetails(pointer: ptr!)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Initializes a `ThresholdKey` object.
    ///
    /// - Parameters:
    ///   - import_share: Share to be imported, optional.
    ///   - input: `ShareStore` to be used, optional.
    ///   - never_initialize_new_key: Do not initialize a new tKey if an existing one is found.
    ///   - include_local_matadata_transitions: Proritize existing metadata transitions over cloud fetched transitions.
    ///   - use_tss: Whether TSS is used or not.
    ///   - device_tss_share: Device share for TSS, optional
    ///   - device_tss_index: Device index for TSS, optional
    ///   - tss_factor_pub: Factor Key for TSS, optional
    ///
    /// - Returns: `KeyDetails`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters.
    public func initialize(import_share: String? = nil, input: ShareStore? = nil, never_initialize_new_key: Bool? = nil, include_local_metadata_transitions: Bool? = nil, use_tss: Bool = false, device_tss_share: String? = nil, device_tss_index: Int32? = nil, tss_factor_pub: KeyPoint? = nil) async throws -> KeyDetails {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.initialize(import_share: import_share, input: input, never_initialize_new_key: never_initialize_new_key, include_local_metadata_transitions: include_local_metadata_transitions, use_tss: use_tss, device_tss_share: device_tss_share, device_tss_index: device_tss_index, tss_factor_pub: tss_factor_pub) {
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
    
    private func reconstruct(completion: @escaping (Result<KeyReconstructionDetails, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let ptr = withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_reconstruct(self.pointer, curvePointer, error)})
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey Reconstruct")
                }
                let result = try! KeyReconstructionDetails(pointer: ptr!)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Reconstructs the private key, this assumes that the number of shares inserted into the `ThrehsoldKey` are equal or greater than the threshold.
    ///
    /// - Throws: `RuntimeError`.
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
    
    /// Returns the latest polynomial.
    ///
    /// - Returns: `Polynomial`
    ///
    /// - Throws: `RuntimeError`, indicates invalid `ThresholdKey`.
    public func reconstruct_latest_poly() throws -> Polynomial {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_reconstruct_latest_poly(pointer, curvePointer,error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey reconstruct_latest_poly")
        }
        return Polynomial(pointer: result!)
    }
    
    /// Returns share stores for the latest polynomial.
    ///
    /// - Returns: `ShareStoreArray`
    ///
    /// - Throws: `RuntimeError`, indicates invalid `ThresholdKey`.
    public func get_all_share_stores_for_latest_polynomial() throws -> ShareStoreArray {
        var errorCode: Int32 = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_all_share_stores_for_latest_polynomial(pointer, curvePointer,error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_all_share_stores_for_latest_polynomial")
        }
        return ShareStoreArray.init(pointer: result!);
    }
    
    
    private func generate_new_share(use_tss: Bool = false, tss_options: TssOptions? = nil, completion: @escaping (Result<GenerateShareStoreResult, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var options: OpaquePointer?
                if tss_options != nil {
                    options = tss_options!.pointer
                }
                
                var errorCode: Int32  = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let ptr = withUnsafeMutablePointer(to: &errorCode, {error in
                    threshold_key_generate_share(self.pointer,curvePointer,use_tss,options, error )
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey generate_new_share")
                }

                let result = try GenerateShareStoreResult( pointer: ptr!)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Generates a new share.
    ///
    /// - Parameters:
    ///   - use_tss: Whether TSS should be used or not..
    ///   - tss_options: TSS options that should be used for TSS.
    ///
    /// - Returns: `GenerateShareStoreArray`
    ///
    /// - Throws: `RuntimeError`, indicates invalid `ThresholdKey`.
    public func generate_new_share(use_tss: Bool = false, tss_options: TssOptions? = nil) async throws -> GenerateShareStoreResult {
        return try await withCheckedThrowingContinuation {
            continuation in self.generate_new_share(use_tss: use_tss, tss_options: tss_options) {
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
    
    private func delete_share(share_index: String,  use_tss: Bool = false, tss_options: TssOptions? = nil, completion: @escaping (Result<Void,Error>) -> Void)  {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let shareIndexPointer = UnsafeMutablePointer<Int8>(mutating: (share_index as NSString).utf8String)
                var options: OpaquePointer?
                if tss_options != nil {
                    options = tss_options!.pointer
                }
                withUnsafeMutablePointer(to: &errorCode, {error in
                    threshold_key_delete_share(self.pointer, shareIndexPointer, curvePointer, use_tss, options, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in Threshold while Deleting share")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Deletes a share at the specified index. Caution is advised to not try delete a share that would prevent the total number of shares being below the threshold.
    /// - Parameters:
    ///   - share_index: Share index to be deleted.
    ///   - use_tss: Whether TSS should be used or not..
    ///   - tss_options: TSS options that should be used for TSS.
    /// - Throws: `RuntimeError`, indicates invalid share index or invalid `ThresholdKey`.
    public func delete_share(share_index: String, use_tss: Bool = false, tss_options: TssOptions? = nil) async throws {
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
    
    private func CRITICAL_delete_tkey(completion: @escaping (Result<Void,Error>) -> Void)  {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, {error in
                    threshold_key_delete_tkey(self.pointer, curvePointer, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in Threshold while Deleting tKey")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Permanently deletes a tKey, this process is irrecoverable.
    ///
    /// - Throws: `RuntimeError`, indicates invalid `ThresholdKey`.
    public func CRITICAL_delete_tkey() async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.CRITICAL_delete_tkey() {
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
    
    /// Returns the key details, mainly used after reconstruction.
    ///
    /// - Returns: `KeyDetails`
    ///
    /// - Throws: `RuntimeError`, indicates invalid `ThresholdKey`.
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
    
    /// Retrieves a specific share.
    ///
    /// - Parameters:
    ///   - shareIndex: The index of the share to output.
    ///   - shareType: The format of the output, can be `"mnemonic"`, optional.
    
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func output_share(shareIndex: String, shareType: String? = nil) throws -> String {
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
        
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }

    /// Converts a share to a `ShareStore`.
    ///
    /// - Parameters:
    ///   - share: Hexadecimal representation of a share as `String`.
    
    /// - Returns: `ShareStore`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameter.
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
    
    private func input_share(share: String, shareType: String?, completion: @escaping (Result<Void,Error>) -> Void)  {
        tkeyQueue.async {
            do {
                var errorCode: Int32  = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let cShare = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)

                var cShareType: UnsafeMutablePointer<Int8>?
                if shareType != nil {
                    cShareType = UnsafeMutablePointer<Int8>(mutating: (shareType! as NSString).utf8String)
                }
                withUnsafeMutablePointer(to: &errorCode, {error in
                    threshold_key_input_share(self.pointer, cShare, cShareType, curvePointer, error )
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey input share")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Inserts a share into `ThresholdKey`, this is used prior to reconstruction in order to ensure the number of shares meet the threshold.
    ///
    /// - Parameters:
    ///   - share: Hex representation of a share as `String`.
    ///   - shareType: The format of the share, can be `"mnemonic"`, optional.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameter of invalid `ThresholdKey`.
    public func input_share(share: String, shareType: String?) async throws {
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

    /// Retrieves a specific `ShareStore`.
    ///
    /// - Parameters:
    ///   - shareIndex: The index of the share to output.
    ///   - polyID: The polynomial id to be used for the output, optional
    
    /// - Returns: `ShareStore`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
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
    
    private func input_share_store(shareStore: ShareStore, completion: @escaping (Result<Void,Error>) -> Void)  {
        tkeyQueue.async {
            do {
                var errorCode: Int32  = -1
                withUnsafeMutablePointer(to: &errorCode, {error in
                    threshold_key_input_share_store(self.pointer, shareStore.pointer, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey input share store")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Inserts a `ShareStore` into `ThresholdKey`, useful for insertion before reconstruction to ensure the number of shares meet the minimum threshold.
    ///
    /// - Parameters:
    ///   - shareStore: The `ShareStore` to be inserted
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
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

    /// Retrieves all share indexes for a `ThresholdKey`.
    ///
    /// - Returns: Array of `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid `ThresholdKey`.
    public func get_shares_indexes() throws -> [String] {
        var errorCode: Int32  = -1
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_get_shares_indexes(pointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_share_indexes")
        }

        let string = String.init(cString: result!)
        let indexes = try! JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [String]
        string_free(result)
        return indexes
    }
    
    /// Encrypts a message.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
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
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
    
    /// Decrypts a message.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func decrypt(msg: String) throws -> String {
        var errorCode: Int32  = -1
        let msgPointer = UnsafeMutablePointer<Int8>(mutating: (msg as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_decrypt(pointer, msgPointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey decrypt")
        }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
    
    /// Returns last metadata fetched from the cloud.
    ///
    /// - Returns: `Metadata`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_last_fetched_cloud_metadata() throws -> Metadata {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_last_fetched_cloud_metadata(pointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_last_fetched_cloud_metadata")
        }
        return Metadata.init(pointer: result)
    }
    
    /// Returns current metadata transitions not yet synchronised.
    ///
    /// - Returns: `LocalMetadataTransitions`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_local_metadata_transitions() throws -> LocalMetadataTransitions {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_local_metadata_transitions(pointer, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_local_metadata_transitions")
        }
        return LocalMetadataTransitions.init(pointer: result!)
    }
    
    /// Returns the tKey store for a module.
    ///
    /// - Parameters:
    ///   - moduleName: Specific name of the module.
    ///
    /// - Returns: Array of objects.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_tkey_store(moduleName: String) throws -> [[String:Any]]  {
        var errorCode: Int32  = -1
        
        let modulePointer = UnsafeMutablePointer<Int8>(mutating: (moduleName as NSString).utf8String)
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_get_tkey_store(pointer, modulePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_tkey_store")
        }

        let string = String.init(cString: result!)
        string_free(result)
        
        let jsonArray = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: .allowFragments) as! [[String:Any]]
        return jsonArray
    }
    
    /// Returns the specific tKey store item json for a module.
    ///
    /// - Parameters:
    ///   - moduleName: Specific name of the module.
    ///   - id: Identifier of the item.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_tkey_store_item(moduleName: String, id: String) throws -> [String:Any] {
        var errorCode: Int32  = -1
        let modulePointer = UnsafeMutablePointer<Int8>(mutating: (moduleName as NSString).utf8String)
        
        let idPointer = UnsafeMutablePointer<Int8>(mutating: (id as NSString).utf8String)
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_get_tkey_store_item(pointer, modulePointer, idPointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_tkey_store_item")
        }
        let string = String.init(cString: result!)
        string_free(result)
        
        let json = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: .allowFragments) as! [String:Any]
        return json
    }
    
    /// Returns all shares according to their mapping.
    ///
    /// - Returns: `ShareStorePolyIdIndexMap`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_shares() throws -> ShareStorePolyIdIndexMap {
        var errorCode: Int32  = -1

        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            threshold_key_get_shares(pointer, error )
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_shares")
        }
        return try ShareStorePolyIdIndexMap.init(pointer: result!)
    }
    
    private func sync_local_metadata_transistions(completion: @escaping (Result<Void,Error>) -> Void)  {
        tkeyQueue.async {
            do {
                var errorCode: Int32  = -1
                
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: self.curveN).utf8String)
                
                withUnsafeMutablePointer(to: &errorCode, {error in
                    threshold_key_sync_local_metadata_transitions(self.pointer, curvePointer, error )
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey sync_local_metadata_transistions")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Syncronises metadata transitions, only used if manual sync is enabled.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
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
    
    /// Returns all shares descriptions.
    ///
    /// - Returns: Array of objects.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_share_descriptions() throws -> [String: [String]] {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_share_descriptions(pointer, error)
        })

        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_share_descriptions")
        }

        let string = String.init(cString: result!)
        string_free(result)
        
        let json = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: .allowFragments) as! [String: [String]]
        return json
    }
    
    private func add_share_description(key: String, description: String, update_metadata: Bool, completion: @escaping (Result<(), Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let keyPointer = UnsafeMutablePointer<Int8>(mutating: (key as NSString).utf8String)
                let descriptionPointer = UnsafeMutablePointer<Int8>(mutating: (description as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_add_share_description(self.pointer, keyPointer, descriptionPointer, update_metadata, curvePointer, error)})
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey add_share_description")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Adds a share description.
    ///
    /// - Parameters:
    ///   - key: The key, usually the share index.
    ///   - description: Description for the key.
    ///   - update_metadata: Whether the metadata is synced immediately or not.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func add_share_description(key: String, description: String, update_metadata: Bool = true) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.add_share_description(key: key, description: description, update_metadata: update_metadata) {
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
    
    private func update_share_description(key: String, oldDescription: String, newDescription: String, update_metadata: Bool, completion: @escaping (Result<(), Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let keyPointer = UnsafeMutablePointer<Int8>(mutating: (key as NSString).utf8String)
                let oldDescriptionPointer = UnsafeMutablePointer<Int8>(mutating: (oldDescription as NSString).utf8String)
                let newDescriptionPointer = UnsafeMutablePointer<Int8>(mutating: (newDescription as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_update_share_description(self.pointer, keyPointer, oldDescriptionPointer, newDescriptionPointer, update_metadata, curvePointer, error)})
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey update_share_description")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Updates a share description.
    ///
    /// - Parameters:
    ///   - key: The relevant key.
    ///   - oldDescription: Old description used for the key
    ///   - newDescription: New description for the key.
    ///   - update_metadata: Whether the metadata is synced immediately or not.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func update_share_description(key: String, oldDescription: String, newDescription: String, update_metadata: Bool = true) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.update_share_description(key: key, oldDescription: oldDescription, newDescription: newDescription, update_metadata: update_metadata) {
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
    
    private func delete_share_description(key: String, description: String, update_metadata: Bool, completion: @escaping (Result<(), Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let keyPointer = UnsafeMutablePointer<Int8>(mutating: (key as NSString).utf8String)
                let descriptionPointer = UnsafeMutablePointer<Int8>(mutating: (description as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_delete_share_description(self.pointer, keyPointer, descriptionPointer, update_metadata, curvePointer, error)})
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey delete_share_description")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Deletes a share description.
    ///
    /// - Parameters:
    ///   - key: The relevant key.
    ///   - description: Current description for the key.
    ///   - update_metadata: Whether the metadata is synced immediately or not.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func delete_share_description(key: String, description: String, update_metadata: Bool = true) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.delete_share_description(key: key, description: description, update_metadata: update_metadata) {
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
    
    private func storage_layer_get_metadata(private_key: String?, completion: @escaping (Result<String, Error>) -> Void ) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                var privateKeyPointer: UnsafeMutablePointer<Int8>?;
                if private_key != nil {
                    privateKeyPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: private_key!).utf8String)
                }
                let ptr = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_metadata(self.pointer, privateKeyPointer, error)})
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey get_metadata")
                }
                let string = String.init(cString: ptr!)
                string_free(ptr)
                completion(.success(string))
            }catch {
                completion(.failure(error))
            }
        }
    }
    
    
    /// Function to retrieve the metadata directly from the network, only used in very specific instances.
    ///
    /// - Parameters:
    ///   - private_key: The reconstructed key, optional.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func storage_layer_get_metadata(private_key: String?) async throws -> String {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.storage_layer_get_metadata(private_key: private_key) {
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
    
    private func storage_layer_set_metadata(private_key: String?, json: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                var privateKeyPointer: UnsafeMutablePointer<Int8>?;
                if private_key != nil {
                    privateKeyPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: private_key!).utf8String)
                }
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let valuePointer = UnsafeMutablePointer<Int8>(mutating: (json as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_set_metadata(self.pointer, privateKeyPointer,valuePointer,curvePointer,error)})
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey set_metadata")
                }
                completion(.success(()))
            }catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Function to set the metadata directly to the network, only used for specific instances.
    ///
    /// - Parameters:
    ///   - private_key: The reconstructed key.
    ///   - json: Relevant json to be set
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func storage_layer_set_metadata(private_key: String?, json: String) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.storage_layer_set_metadata(private_key: private_key, json: json) {
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
    
    private func storage_layer_set_metadata_stream(private_keys: String, json: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let privateKeysPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: private_keys).utf8String)
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let valuesPointer = UnsafeMutablePointer<Int8>(mutating: (json as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_set_metadata_stream(self.pointer, privateKeysPointer,valuesPointer,curvePointer,error)})
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey set_metadata_stream")
                }
                completion(.success(()))
            }catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Function to set the metadata directly to the network, only used for specific instances.
    ///
    /// - Parameters:
    ///   - private_keys: The relevant private keys.
    ///   - json: Relevant json to be set
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func storage_layer_set_metadata_stream(private_keys: String, json: String) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.storage_layer_set_metadata_stream(private_keys: private_keys, json: json) {
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
    
    
    public func service_provider_assign_public_key(tag: String, json: String, nonce: String, public_key: String) throws {
                var errorCode: Int32 = -1
                let tagPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: tag).utf8String)
                let noncePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: nonce).utf8String)
                let publicPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: public_key).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_service_provider_assign_tss_public_key(self.pointer, tagPointer,noncePointer,publicPointer,error)})
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey, service_provider_assign_public_key")
                }
        }
    
    
    public func get_all_tss_tags() throws -> [String]{
        var errorCode: Int32 = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_all_tss_tags(self.pointer, error )})
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_all_tss_tags")
        }
        let string = String.init(cString: result!)
        string_free(result)
        guard let data = string.data(using: .utf8) else {
            throw RuntimeError("Error in get_all_tss_tag : Invalid output ")
        }
        guard let result_vec = try JSONSerialization.jsonObject(with: data ) as? [String] else {
            throw RuntimeError("Error in get_all_tss_tag : Invalid output ")
        }
        
        return result_vec
    }
    
    public func get_extended_verifier_id() throws -> String {
        var errorCode: Int32 = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_extended_verifier_id(self.pointer, error )})
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_all_tss_tags")
        }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
    
    deinit {
        threshold_key_free(pointer)
    }
}
