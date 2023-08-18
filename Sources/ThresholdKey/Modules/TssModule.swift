import Foundation

#if canImport(lib)
    import lib
#endif
import CommonSources
import FetchNodeDetails
import TorusUtils

public struct GetTSSPubKeyResult: Codable {
    public struct Point: Codable {
        
        // swiftlint:disable:next identifier_name
        public var x: String
        // swiftlint:disable:next identifier_name
        public var y: String

        public func toFullAddr() -> String {
            return "04" + x + y
        }
    }

    public var publicKey: Point
    public var nodeIndexes: [Int]
}


// swiftlint:disable type_body_length
public final class TssModule {
    private static func set_tss_tag(thresholdKey: ThresholdKey, tssTag: String, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let tssTagPointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: tssTag).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_set_tss_tag(thresholdKey.pointer, tssTagPointer, error) })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey set_tss_tag")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    static func set_tss_tag(thresholdKey: ThresholdKey, tssTag: String) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag) {
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

    public static func get_tss_tag(thresholdKey: ThresholdKey) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_tag(thresholdKey.pointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_tss_tag")
        }
        let string = String(cString: result!)
        string_free(result)
        return string
    }

    public static func get_all_tss_tags(thresholdKey: ThresholdKey) throws -> [String] {
        var errorCode: Int32 = -1

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_all_tss_tags(thresholdKey.pointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_tss_tag")
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

    public static func get_all_factor_pub(thresholdKey: ThresholdKey, tssTag: String) async throws -> [String] {
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)

        var errorCode: Int32 = -1

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_tag_factor_pub(thresholdKey.pointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_all_factor_pub")
        }
        let string = String(cString: result!)
        string_free(result)
        guard let data = string.data(using: .utf8) else {
            throw RuntimeError("Error in get_all_factor_pub : Invalid output ")
        }
        guard let resultVec = try JSONSerialization.jsonObject(with: data) as? [String] else {
            throw RuntimeError("Error in get_all_factor_pub : Invalid output ")
        }

        return resultVec
    }

    public static func get_tss_pub_key(thresholdKey: ThresholdKey, tssTag: String) async throws -> String {
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)

        var errorCode: Int32 = -1

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_public_key(thresholdKey.pointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in get_tss_tag")
        }
        let string = String(cString: result!)
        string_free(result)
        return string
    }

    public static func get_tss_nonce(thresholdKey: ThresholdKey, tssTag: String, prefetch: Bool = false) throws -> Int32 {
        var errorCode: Int32 = -1
        let tssTagPointer: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: NSString(string: tssTag).utf8String)
        var nonce = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_nonce(thresholdKey.pointer, tssTagPointer, error) })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_tss_nonce")
        }

        if prefetch {
            nonce += 1
        }

        return nonce
    }

    public static func get_tss_share(thresholdKey: ThresholdKey, tssTag: String, factorKey: String, threshold: Int32 = 0) async throws -> (String, String) {
        if factorKey.count > 66 { throw RuntimeError("Invalid factor Key") }
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)

        var errorCode: Int32 = -1

        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)
        let factorKeyPointer = UnsafeMutablePointer<Int8>(mutating: (factorKey as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            threshold_key_get_tss_share(thresholdKey.pointer, factorKeyPointer, threshold, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ThresholdKey get_tss_share")
        }
        let string = String(cString: result!)
        string_free(result)
        let splitString = string.split(separator: ",", maxSplits: 2)
        return (String(splitString[0]), String(splitString[1]))
    }

    private static func create_tagged_tss_share(thresholdKey: ThresholdKey, deviceTssShare: String?, factorPub: String, deviceTssIndex: Int32, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1

                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)
                var deviceTssSharePointer: UnsafeMutablePointer<Int8>?
                if let deviceTssShare = deviceTssShare {
                    deviceTssSharePointer = UnsafeMutablePointer<Int8>(mutating: (deviceTssShare as NSString).utf8String)
                }
                let factorPubPointer = UnsafeMutablePointer<Int8>(mutating: (factorPub as NSString).utf8String)

                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_create_tagged_tss_share(thresholdKey.pointer, deviceTssSharePointer, factorPubPointer, deviceTssIndex, curvePointer, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey create_tagged_tss_share")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public static func create_tagged_tss_share(thresholdKey: ThresholdKey, tssTag: String, deviceTssShare: String?,
                                               factorPub: String, deviceTssIndex: Int32, nodeDetails: AllNodeDetailsModel, torusUtils: TorusUtils) async throws {
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)
        try await TssModule.update_tss_pub_key(thresholdKey: thresholdKey, tssTag: tssTag, nodeDetails: nodeDetails, torusUtils: torusUtils)
        return try await withCheckedThrowingContinuation {
            continuation in
            create_tagged_tss_share(thresholdKey: thresholdKey, deviceTssShare: deviceTssShare, factorPub: factorPub, deviceTssIndex: deviceTssIndex) {
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

    private static func update_tss_pub_key(thresholdKey: ThresholdKey, tssTag: String, nonce: String, publicKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                try thresholdKey.service_provider_assign_public_key(tag: tssTag, nonce: nonce, publicKey: publicKey)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public static func update_tss_pub_key(thresholdKey: ThresholdKey, tssTag: String, nodeDetails: AllNodeDetailsModel, torusUtils: TorusUtils, prefetch: Bool = false) async throws {
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)

        let nonce = String(try get_tss_nonce(thresholdKey: thresholdKey, tssTag: tssTag, prefetch: prefetch))

        let publicAddress = try await get_dkg_pub_key(thresholdKey: thresholdKey, tssTag: tssTag, nonce: nonce, nodeDetails: nodeDetails, torusUtils: torusUtils)
        let pkEncoded = try JSONEncoder().encode(publicAddress)
        guard let publicKey = String(data: pkEncoded, encoding: .utf8) else {
            throw RuntimeError("update_tss_pub_key - Conversion Error - ResultString")
        }

        return try await withCheckedThrowingContinuation {
            continuation in
            update_tss_pub_key(thresholdKey: thresholdKey, tssTag: tssTag, nonce: nonce, publicKey: publicKey) {
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

    private static func copy_factor_pub(thresholdKey: ThresholdKey, factorKey: String, newFactorPub: String, tssIndex: Int32, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1

                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)
                let factorKeyPointer = UnsafeMutablePointer<Int8>(mutating: (factorKey as NSString).utf8String)
                let newFactorPubPointer = UnsafeMutablePointer<Int8>(mutating: (newFactorPub as NSString).utf8String)

                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_copy_factor_pub(thresholdKey.pointer, newFactorPubPointer, tssIndex, factorKeyPointer, curvePointer, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey copy_factor_pub")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public static func copy_factor_pub(thresholdKey: ThresholdKey, tssTag: String, factorKey: String, newFactorPub: String, tssIndex: Int32, threshold: Int32 = 0) async throws {
        if factorKey.count > 66 { throw RuntimeError("Invalid factor Key") }
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)

        return try await withCheckedThrowingContinuation {
            continuation in
            copy_factor_pub(thresholdKey: thresholdKey, factorKey: factorKey, newFactorPub: newFactorPub, tssIndex: tssIndex) {
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

    private static func generate_tss_share(thresholdKey: ThresholdKey, inputTssShare: String, tssInputIndex: Int32, authSignatures: [String], newFactorPub: String,
                                           newTssIndex: Int32, selectedServers: [Int32]? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)

                let authSignaturesJson = try JSONSerialization.data(withJSONObject: authSignatures)
                guard let authSignaturesStr = String(data: authSignaturesJson, encoding: .utf8) else {
                    throw RuntimeError("auth signatures error")
                }
                let inputSharePointer = UnsafeMutablePointer<Int8>(mutating: (inputTssShare as NSString).utf8String)
                let newFactorPubPointer = UnsafeMutablePointer<Int8>(mutating: (newFactorPub as NSString).utf8String)

                let authSignaturesPointer = UnsafeMutablePointer<Int8>(mutating: (authSignaturesStr as NSString).utf8String)

                var serversPointer: UnsafeMutablePointer<Int8>?
                if selectedServers != nil {
                    let selectedServersJson = try JSONSerialization.data(withJSONObject: selectedServers as Any)
                    let selectedServersStr = String(data: selectedServersJson, encoding: .utf8)!
                    serversPointer = UnsafeMutablePointer<Int8>(mutating: (selectedServersStr as NSString).utf8String)
                }

                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_generate_tss_share(thresholdKey.pointer, inputSharePointer, tssInputIndex, newTssIndex, newFactorPubPointer,
                                                     serversPointer, authSignaturesPointer, curvePointer, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey generate_tss_share")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    
    // swiftlint:disable:next function_parameter_count
    public static func generate_tss_share(thresholdKey: ThresholdKey, tssTag: String, inputTssShare: String, tssInputIndex: Int32, authSignatures: [String],
                                          newFactorPub: String, newTssIndex: Int32, nodeDetails: AllNodeDetailsModel, torusUtils: TorusUtils, selectedServers: [Int32]? = nil) async throws {
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)

        try await update_tss_pub_key(thresholdKey: thresholdKey, tssTag: tssTag, nodeDetails: nodeDetails, torusUtils: torusUtils, prefetch: true)

        return try await withCheckedThrowingContinuation {
            continuation in
            generate_tss_share(thresholdKey: thresholdKey, inputTssShare: inputTssShare, tssInputIndex: tssInputIndex, authSignatures: authSignatures,
                               newFactorPub: newFactorPub, newTssIndex: newTssIndex) {
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

    private static func delete_tss_share(thresholdKey: ThresholdKey, inputTssShare: String, tssInputIndex: Int32, authSignatures: [String],
                                         deleteFactorPub: String, selectedServers: [Int32]? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)

                let authSignaturesJson = try JSONSerialization.data(withJSONObject: authSignatures)
                guard let authSignaturesStr = String(data: authSignaturesJson, encoding: .utf8) else {
                    throw RuntimeError("auth signatures error")
                }
                let inputSharePointer = UnsafeMutablePointer<Int8>(mutating: (inputTssShare as NSString).utf8String)
                let factorPubPointer = UnsafeMutablePointer<Int8>(mutating: (deleteFactorPub as NSString).utf8String)

                let authSignaturesPointer = UnsafeMutablePointer<Int8>(mutating: (authSignaturesStr as NSString).utf8String)

                var serversPointer: UnsafeMutablePointer<Int8>?
                if selectedServers != nil {
                    let selectedServersJson = try JSONSerialization.data(withJSONObject: selectedServers as Any)
                    let selectedServersStr = String(data: selectedServersJson, encoding: .utf8)!
                    serversPointer = UnsafeMutablePointer<Int8>(mutating: (selectedServersStr as NSString).utf8String)
                }

                withUnsafeMutablePointer(to: &errorCode, { error in
                    threshold_key_delete_tss_share(thresholdKey.pointer, inputSharePointer, tssInputIndex, factorPubPointer, serversPointer, authSignaturesPointer, curvePointer, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in ThresholdKey delete tss share")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public static func delete_tss_share(thresholdKey: ThresholdKey, tssTag: String, inputTssShare: String, tssInputIndex: Int32, authSignatures: [String],
                                        deleteFactorPub: String, nodeDetails: AllNodeDetailsModel, torusUtils: TorusUtils, selectedServers: [Int32]? = nil) async throws {
        try await update_tss_pub_key(thresholdKey: thresholdKey, tssTag: tssTag, nodeDetails: nodeDetails, torusUtils: torusUtils, prefetch: true)
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)

        return try await withCheckedThrowingContinuation {
            continuation in
            delete_tss_share(thresholdKey: thresholdKey, inputTssShare: inputTssShare, tssInputIndex: tssInputIndex, authSignatures: authSignatures, deleteFactorPub: deleteFactorPub) {
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

    public static func add_factor_pub(thresholdKey: ThresholdKey, tssTag: String, factorKey: String, authSignatures: [String], newFactorPub: String,
                                      newTssIndex: Int32, selectedServers: [Int32]? = nil, nodeDetails: AllNodeDetailsModel, torusUtils: TorusUtils) async throws {
        if factorKey.count > 66 { throw RuntimeError("Invalid factor Key") }
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)

        let (tssIndex, tssShare) = try await get_tss_share(thresholdKey: thresholdKey, tssTag: tssTag, factorKey: factorKey)
        try await TssModule.generate_tss_share(thresholdKey: thresholdKey, tssTag: tssTag, inputTssShare: tssShare, tssInputIndex: Int32(tssIndex)!,
                                               authSignatures: authSignatures, newFactorPub: newFactorPub, newTssIndex: newTssIndex, nodeDetails: nodeDetails,
                                               torusUtils: torusUtils, selectedServers: selectedServers)

    }

    public static func delete_factor_pub(thresholdKey: ThresholdKey, tssTag: String, factorKey: String, authSignatures: [String], deleteFactorPub: String,
                                         nodeDetails: AllNodeDetailsModel, torusUtils: TorusUtils, selectedServers: [Int32]? = nil) async throws {
        if factorKey.count > 66 { throw RuntimeError("Invalid factor Key") }
        try await TssModule.set_tss_tag(thresholdKey: thresholdKey, tssTag: tssTag)

        let (tssIndex, tssShare) = try await get_tss_share(thresholdKey: thresholdKey, tssTag: tssTag, factorKey: factorKey)
        try await TssModule.delete_tss_share(thresholdKey: thresholdKey, tssTag: tssTag, inputTssShare: tssShare, tssInputIndex: Int32(tssIndex)!,
                                             authSignatures: authSignatures, deleteFactorPub: deleteFactorPub, nodeDetails: nodeDetails, torusUtils: torusUtils,
                                             selectedServers: selectedServers)
    }

    /// backup device share with factor key  
    /// - Parameters:
    ///   - thresholdKey: The threshold key to act on.
    ///   - shareIndex: Index of the Share to be backed up.
    ///   - factorKey: factor key to be used for backup.
    ///
    /// - Returns: `Void`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func backup_share_with_factor_key(thresholdKey: ThresholdKey, shareIndex: String, factorKey: String) throws {
        var errorCode: Int32 = -1

        let cShareIndex = UnsafeMutablePointer<Int8>(mutating: (shareIndex as NSString).utf8String)
        let cFactorKey = UnsafeMutablePointer<Int8>(mutating: (factorKey as NSString).utf8String)
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)

        withUnsafeMutablePointer(to: &errorCode, { error in threshold_key_backup_share_with_factor_key( thresholdKey.pointer, cShareIndex, cFactorKey, curvePointer, error)})
         guard errorCode == 0 else {
             throw RuntimeError("Error in ThresholdKey backup_share_with_factor_key")
         }
    }

    public static func find_device_share_index ( thresholdKey: ThresholdKey, factorKey: String ) async throws -> String {
        let result = try await thresholdKey.storage_layer_get_metadata(privateKey: factorKey)
        guard let resultData = result.data(using: .utf8) else {
            throw "Invalid factor key"
        }
        guard let resultJson = try JSONSerialization.jsonObject(with: resultData ) as? [String: Any] else {
            throw "Invalid factor key"
        }
        guard let deviceShareJson = resultJson["deviceShare"] as? [String: Any] else {
            throw "Invalid factor key"
        }
        guard let shareJson = deviceShareJson["share"] as? [String: Any] else {
            throw "Invalid factor key"
        }
        guard let shareIndex = shareJson["shareIndex"] as? String else {
            throw "Invalid factor key"
        }
        return shareIndex
    }

    /// get dkg public key
    /// - Parameters:
    ///   - thresholdKey: The threshold key to act on.
    ///   - tssTag: tssTag used.
    ///   - nonce: nonce 
    ///   - nodeDetails: node details
    ///   - torusUtils: torus utils
    /// - Returns: `GetTSSPubKeyResult`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func get_dkg_pub_key(thresholdKey: ThresholdKey, tssTag: String, nonce: String, nodeDetails: AllNodeDetailsModel, torusUtils: TorusUtils) async throws -> GetTSSPubKeyResult {
        let extendedVerifierId = try thresholdKey.get_extended_verifier_id()
        let split = extendedVerifierId.components(separatedBy: "\u{001c}")

        let result = try await torusUtils.getPublicAddress(endpoints: nodeDetails.torusNodeEndpoints, torusNodePubs: nodeDetails.torusNodePub,
                                                           verifier: split[0], verifierId: split[1], extendedVerifierId: "\(split[1])\u{0015}\(tssTag)\u{0016}\(nonce)")

        print("result in service provider", result)
        guard let valueX = result.finalKeyData?.X, let valueY = result.finalKeyData?.Y, let nodeIndexes = result.nodesData?.nodeIndexes else {
            throw RuntimeError("conversion error")
        }
        let pubKey = GetTSSPubKeyResult.Point(x: valueX, y: valueY)
        return GetTSSPubKeyResult(publicKey: pubKey, nodeIndexes: nodeIndexes)
    }
}
