import Foundation
#if canImport(lib)
    import lib
#endif
import CommonSources
import TorusUtils

// swiftlint:disable file_length
// swiftlint:disable type_body_length
public class ThresholdKey {
    private(set) var pointer: OpaquePointer?
    private(set) var useTss: Bool = false
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
    internal let tkeyQueue = DispatchQueue(label: "thresholdkey.queue")

    /// Instantiate a `ThresholdKey` object,
    ///
    /// - Parameters:
    ///   - metadata: Existing metadata to be used, optional.
    ///   - shares: Existing shares to be used, optional.
    ///   - storageLayer: Storage layer to be used.
    ///   - serviceProvider: Service provider to be used, optional only in the most basic usage of tKey.
    ///   - localMetadataTransitions: Existing local transitions to be used.
    ///   - lastFetchCloudMetadata: Existing cloud metadata to be used.
    ///   - enableLogging: Determines whether logging is available or not (pending).
    ///   - manualSync: Determines if changes to the metadata are automatically synced.
    ///   - rssComm: RSS client, required for TSS.
    ///
    /// - Returns: `ThresholdKey`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters.
    public init(metadata: Metadata? = nil, shares: ShareStorePolyIdIndexMap? = nil, storageLayer: StorageLayer,
                serviceProvider: ServiceProvider? = nil, localMetadataTransitions: LocalMetadataTransitions? = nil,
                lastFetchCloudMetadata: Metadata? = nil, enableLogging: Bool, manualSync: Bool, rssComm: RssComm? = nil) throws {
        var errorCode: Int32 = -1
        var providerPointer: OpaquePointer?
        if case let .some(provider) = serviceProvider {
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

        if metadata != nil {
            metadataPointer = metadata!.pointer
        }

        if lastFetchCloudMetadata != nil {
            cloudMetadataPointer = lastFetchCloudMetadata!.pointer
        }

        if localMetadataTransitions != nil {
            transitionsPointer = localMetadataTransitions!.pointer
        }

        if rssComm != nil {
            rssCommPtr = rssComm!.pointer
            useTss = true
        }

        let result = withUnsafeMutablePointer(to: &errorCode, { error -> OpaquePointer in
            threshold_key(metadataPointer, sharesPointer, storageLayer.pointer, providerPointer, transitionsPointer, cloudMetadataPointer, enableLogging, manualSync, rssCommPtr, error)
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
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_current_metadata(pointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_metadata")
        }
        return Metadata(pointer: result!)
    }

    private func initialize(importShare: String?, input: ShareStore?, neverInitializeNewKey: Bool?, includeLocalMetadataTransitions: Bool?,
                            useTss: Bool = false, deviceTssShare: String?, deviceTssIndex: Int32?, tssFactorPub: KeyPoint?,
                            completion: @escaping (Result<KeyDetails, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                var sharePointer: UnsafeMutablePointer<Int8>?
                var tssDeviceSharePointer: UnsafeMutablePointer<Int8>?
                var tssFactorPubPointer: OpaquePointer?
                var deviceIndex: Int32 = deviceTssIndex ?? 2
                if importShare != nil {
                    sharePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: importShare!).utf8String)
                }

                if deviceTssShare != nil {
                    tssDeviceSharePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: deviceTssShare!).utf8String)
                }

                if tssFactorPub != nil {
                    tssFactorPubPointer = tssFactorPub!.pointer
                }

                var storePtr: OpaquePointer?
                if input != nil {
                    storePtr = input!.pointer
                }

                let neverInitializeNewKey = neverInitializeNewKey ?? false
                let includeLocalMetadataTransitions = includeLocalMetadataTransitions ?? false

                let curvePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: self.curveN).utf8String)
                let ptr = withUnsafeMutablePointer(to: &deviceIndex, { tssDeviceIndexPointer in withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_initialize(self.pointer, sharePointer, storePtr, neverInitializeNewKey, includeLocalMetadataTransitions,
                                             curvePointer, useTss, tssDeviceSharePointer, tssDeviceIndexPointer, tssFactorPubPointer, error) }) })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey Initialize")
                }
                let result = try KeyDetails(pointer: ptr!)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Initializes a `ThresholdKey` object.
    ///
    /// - Parameters:
    ///   - importShare: Share to be imported, optional.
    ///   - input: `ShareStore` to be used, optional.
    ///   - neverInitializeNewKey: Do not initialize a new tKey if an existing one is found.
    ///   - includeLocalMetadataTransitions: Proritize existing metadata transitions over cloud fetched transitions.
    ///   - useTss: Whether TSS is used or not.
    ///   - deviceTssShare: Device share for TSS, optional
    ///   - deviceTssIndex: Device index for TSS, optional
    ///   - tssFactorPub: Factor Key for TSS, optional
    ///
    /// - Returns: `KeyDetails`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters.
    public func initialize(importShare: String? = nil, input: ShareStore? = nil, neverInitializeNewKey: Bool? = nil,
                           includeLocalMetadataTransitions: Bool? = nil, useTss: Bool = false, deviceTssShare: String? = nil,
                           deviceTssIndex: Int32? = nil, tssFactorPub: KeyPoint? = nil) async throws -> KeyDetails {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.initialize(importShare: importShare, input: input, neverInitializeNewKey: neverInitializeNewKey,
                            includeLocalMetadataTransitions: includeLocalMetadataTransitions, useTss: useTss, deviceTssShare: deviceTssShare,
                            deviceTssIndex: deviceTssIndex, tssFactorPub: tssFactorPub) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
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
                    threshold_key_reconstruct(self.pointer, curvePointer, error) })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey Reconstruct")
                }
                let result = try KeyReconstructionDetails(pointer: ptr!)
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
            self.reconstruct {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
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
            threshold_key_reconstruct_latest_poly(pointer, curvePointer, error)
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
            threshold_key_get_all_share_stores_for_latest_polynomial(pointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_all_share_stores_for_latest_polynomial")
        }
        return ShareStoreArray(pointer: result!)
    }

    private func generate_new_share(useTss: Bool = false, tssOptions: TssOptions? = nil, completion: @escaping (Result<GenerateShareStoreResult, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var options: OpaquePointer?
                if tssOptions != nil {
                    options = tssOptions!.pointer
                }

                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let ptr = withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_generate_share(self.pointer, curvePointer, useTss, options, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey generate_new_share")
                }

                let result = try GenerateShareStoreResult(pointer: ptr!)
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
    public func generate_new_share(useTss: Bool = false, tssOptions: TssOptions? = nil) async throws -> GenerateShareStoreResult {
        return try await withCheckedThrowingContinuation {
            continuation in self.generate_new_share(useTss: useTss, tssOptions: tssOptions) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func delete_share(shareIndex: String, useTss: Bool = false, tssOptions: TssOptions? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let shareIndexPointer = UnsafeMutablePointer<Int8>(mutating: (shareIndex as NSString).utf8String)
                var options: OpaquePointer?
                if tssOptions != nil {
                    options = tssOptions!.pointer
                }
                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_delete_share(self.pointer, shareIndexPointer, curvePointer, useTss, options, error)
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
    public func delete_share(shareIndex: String, useTss: Bool = false, tssOptions: TssOptions? = nil) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.delete_share(shareIndex: shareIndex) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func CRITICAL_delete_tkey(completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
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
            self.CRITICAL_delete_tkey {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
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
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_key_details(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Threshold while Getting Key Details")
        }
        return try KeyDetails(pointer: result!)
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
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let cShareIndex = UnsafeMutablePointer<Int8>(mutating: (shareIndex as NSString).utf8String)

        var cShareType: UnsafeMutablePointer<Int8>?
        if shareType != nil {
            cShareType = UnsafeMutablePointer<Int8>(mutating: (shareType! as NSString).utf8String)
        }
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_output_share(pointer, cShareIndex, cShareType, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey output_share")
        }

        let string = String(cString: result!)
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
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let sharePointer = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_share_to_share_store(pointer, sharePointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey share_to_share_store")
        }
        return ShareStore(pointer: result!)
    }

    private func input_share(share: String, shareType: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let cShare = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)

                var cShareType: UnsafeMutablePointer<Int8>?
                if shareType != nil {
                    cShareType = UnsafeMutablePointer<Int8>(mutating: (shareType! as NSString).utf8String)
                }
                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_input_share(self.pointer, cShare, cShareType, curvePointer, error)
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
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
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
    public func output_share_store(shareIndex: String, polyId: String?) throws -> ShareStore {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let cShareIndex = UnsafeMutablePointer<Int8>(mutating: (shareIndex as NSString).utf8String)

        var cPolyId: UnsafeMutablePointer<Int8>?
        if let polyId = polyId {
            cPolyId = UnsafeMutablePointer<Int8>(mutating: (polyId as NSString).utf8String)
        }
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_output_share_store(pointer, cShareIndex, cPolyId, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey output share store")
        }
        return ShareStore(pointer: result!)
    }

    private func input_share_store(shareStore: ShareStore, completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                withUnsafeMutablePointer(to: &errorCode, { error in
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
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func input_factor_key(factorKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let cFactorKey = UnsafeMutablePointer<Int8>(mutating: (factorKey as NSString).utf8String)

                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_input_factor_key(self.pointer, cFactorKey, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey input_factor_key")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Inserts a `ShareStore` into `ThresholdKey` using `FactorKey`, useful for insertion before reconstruction to ensure the number of shares meet the minimum threshold.
    ///
    /// - Parameters:
    ///   - factorKey  : The `factorKey` to be inserted
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func input_factor_key(factorKey: String) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.input_factor_key(factorKey: factorKey) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
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
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_shares_indexes(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_share_indexes")
        }

        let string = String(cString: result!)
        guard let indexes = try JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as? [String] else {
            throw RuntimeError("JsonSerialization Error")
        }
        string_free(result)
        return indexes
    }

    /// Encrypts a message.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func encrypt(msg: String) throws -> String {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let msgPointer = UnsafeMutablePointer<Int8>(mutating: (msg as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_encrypt(pointer, msgPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey encrypt")
        }
        let string = String(cString: result!)
        string_free(result)
        return string
    }

    /// Decrypts a message.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func decrypt(msg: String) throws -> String {
        var errorCode: Int32 = -1
        let msgPointer = UnsafeMutablePointer<Int8>(mutating: (msg as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_decrypt(pointer, msgPointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey decrypt")
        }
        let string = String(cString: result!)
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
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_last_fetched_cloud_metadata(pointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_last_fetched_cloud_metadata")
        }
        return Metadata(pointer: result)
    }

    /// Returns current metadata transitions not yet synchronised.
    ///
    /// - Returns: `LocalMetadataTransitions`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_local_metadata_transitions() throws -> LocalMetadataTransitions {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_local_metadata_transitions(pointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_local_metadata_transitions")
        }
        return LocalMetadataTransitions(pointer: result!)
    }

    /// Returns add metadata transitions , need sync localmetadata transistion to update server data
    ///
    /// - Parameters:
    ///   - input_json: input in json string
    ///   - private_key: private key used to encrypt and store.
    /// - Returns: `Void`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
     public func add_local_metadata_transitions( inputJson: String, privateKey: String ) throws {
         var errorCode: Int32 = -1

         let curve = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
         let input = UnsafeMutablePointer<Int8>(mutating: (inputJson as NSString).utf8String)
         let privateKey = UnsafeMutablePointer<Int8>(mutating: (privateKey as NSString).utf8String)
         withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_add_local_metadata_transitions(pointer, input, privateKey, curve, error)})
         guard errorCode == 0 else {
             throw RuntimeError("Error in ThresholdKey add_local_metadata_transitions")
         }
     }

    /// Returns the tKey store for a module.
    ///
    /// - Parameters:
    ///   - moduleName: Specific name of the module.
    ///
    /// - Returns: Array of objects.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_tkey_store(moduleName: String) throws -> [[String: Any]] {
        var errorCode: Int32 = -1

        let modulePointer = UnsafeMutablePointer<Int8>(mutating: (moduleName as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tkey_store(pointer, modulePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_tkey_store")
        }

        let string = String(cString: result!)
        string_free(result)

        guard let jsonArray = try JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: .allowFragments) as? [[String: Any]] else {
            throw RuntimeError("JsonSerialization Error")
        }
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
    public func get_tkey_store_item(moduleName: String, id: String) throws -> [String: Any] {
        var errorCode: Int32 = -1
        let modulePointer = UnsafeMutablePointer<Int8>(mutating: (moduleName as NSString).utf8String)

        let idPointer = UnsafeMutablePointer<Int8>(mutating: (id as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tkey_store_item(pointer, modulePointer, idPointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_tkey_store_item")
        }
        let string = String(cString: result!)
        string_free(result)

        guard let json = try JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: .allowFragments) as? [String: Any] else {
            throw RuntimeError("JsonSerialization Error")
        }
        return json
    }

    /// Returns all shares according to their mapping.
    ///
    /// - Returns: `ShareStorePolyIdIndexMap`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func get_shares() throws -> ShareStorePolyIdIndexMap {
        var errorCode: Int32 = -1

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_shares(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_shares")
        }
        return try ShareStorePolyIdIndexMap(pointer: result!)
    }

    private func sync_local_metadata_transistions(completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1

                let curvePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: self.curveN).utf8String)

                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_sync_local_metadata_transitions(self.pointer, curvePointer, error)
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
            self.sync_local_metadata_transistions {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
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

        let string = String(cString: result!)
        string_free(result)

        guard let json = try JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: .allowFragments) as? [String: [String]] else {
            throw RuntimeError("JsonSerialization Error")
        }
        return json
    }

    private func add_share_description(key: String, description: String, updateMetadata: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let keyPointer = UnsafeMutablePointer<Int8>(mutating: (key as NSString).utf8String)
                let descriptionPointer = UnsafeMutablePointer<Int8>(mutating: (description as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_add_share_description(self.pointer, keyPointer, descriptionPointer, updateMetadata, curvePointer, error) })
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
    ///   - updateMetadata: Whether the metadata is synced immediately or not.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func add_share_description(key: String, description: String, updateMetadata: Bool = true) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.add_share_description(key: key, description: description, updateMetadata: updateMetadata) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func update_share_description(key: String, oldDescription: String, newDescription: String, updateMetadata: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let keyPointer = UnsafeMutablePointer<Int8>(mutating: (key as NSString).utf8String)
                let oldDescriptionPointer = UnsafeMutablePointer<Int8>(mutating: (oldDescription as NSString).utf8String)
                let newDescriptionPointer = UnsafeMutablePointer<Int8>(mutating: (newDescription as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_update_share_description(self.pointer, keyPointer, oldDescriptionPointer, newDescriptionPointer, updateMetadata, curvePointer, error) })
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
    ///   - updateMetadata: Whether the metadata is synced immediately or not.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func update_share_description(key: String, oldDescription: String, newDescription: String, updateMetadata: Bool = true) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.update_share_description(key: key, oldDescription: oldDescription, newDescription: newDescription, updateMetadata: updateMetadata) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func delete_share_description(key: String, description: String, updateMetadata: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let keyPointer = UnsafeMutablePointer<Int8>(mutating: (key as NSString).utf8String)
                let descriptionPointer = UnsafeMutablePointer<Int8>(mutating: (description as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_delete_share_description(self.pointer, keyPointer, descriptionPointer, updateMetadata, curvePointer, error) })
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
    ///   - updateMetadata: Whether the metadata is synced immediately or not.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters or invalid `ThresholdKey`.
    public func delete_share_description(key: String, description: String, updateMetadata: Bool = true) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.delete_share_description(key: key, description: description, updateMetadata: updateMetadata) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func storage_layer_get_metadata(privateKey: String?, completion: @escaping (Result<String, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                var privateKeyPointer: UnsafeMutablePointer<Int8>?
                if privateKey != nil {
                    privateKeyPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: privateKey!).utf8String)
                }
                let ptr = withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_get_metadata(self.pointer, privateKeyPointer, error) })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey get_metadata")
                }
                let string = String(cString: ptr!)
                string_free(ptr)
                completion(.success(string))
            } catch {
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
    public func storage_layer_get_metadata(privateKey: String?) async throws -> String {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.storage_layer_get_metadata(privateKey: privateKey) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func storage_layer_set_metadata(privateKey: String?, json: String, completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                var privateKeyPointer: UnsafeMutablePointer<Int8>?
                if privateKey != nil {
                    privateKeyPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: privateKey!).utf8String)
                }
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let valuePointer = UnsafeMutablePointer<Int8>(mutating: (json as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_set_metadata(self.pointer, privateKeyPointer, valuePointer, curvePointer, error) })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey set_metadata")
                }
                completion(.success(()))
            } catch {
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
    public func storage_layer_set_metadata(privateKey: String?, json: String) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.storage_layer_set_metadata(privateKey: privateKey, json: json) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func storage_layer_set_metadata_stream(privateKeys: String, json: String, completion: @escaping (Result<Void, Error>) -> Void) {
        tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let privateKeysPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: privateKeys).utf8String)
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (self.curveN as NSString).utf8String)
                let valuesPointer = UnsafeMutablePointer<Int8>(mutating: (json as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_set_metadata_stream(self.pointer, privateKeysPointer, valuesPointer, curvePointer, error) })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey set_metadata_stream")
                }
                completion(.success(()))
            } catch {
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
    public func storage_layer_set_metadata_stream(privateKeys: String, json: String) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            self.storage_layer_set_metadata_stream(privateKeys: privateKeys, json: json) {
                result in
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func service_provider_assign_public_key(tag: String, nonce: String, publicKey: String) throws {
        var errorCode: Int32 = -1
        let tagPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: tag).utf8String)
        let noncePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: nonce).utf8String)
        let publicPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: publicKey).utf8String)
        withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_service_provider_assign_tss_public_key(self.pointer, tagPointer, noncePointer, publicPointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey, service_provider_assign_public_key")
        }
    }

    public func get_all_tss_tags() throws -> [String] {
        var errorCode: Int32 = -1

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_all_tss_tags(self.pointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_all_tss_tags")
        }
        let string = String(cString: result!)
        string_free(result)
        guard let data = string.data(using: .utf8) else {
            throw RuntimeError("Error in get_all_tss_tag : Invalid output ")
        }
        guard let resultVec = try JSONSerialization.jsonObject(with: data) as? [String] else {
            throw RuntimeError("Error in get_all_tss_tag : Invalid output ")
        }

        return resultVec
    }

    public func get_extended_verifier_id() throws -> String {
        var errorCode: Int32 = -1

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_extended_verifier_id(self.pointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_extended_verifier_id")
        }
        let string = String(cString: result!)
        string_free(result)
        return string
    }

    deinit {
        threshold_key_free(pointer)
    }
}
