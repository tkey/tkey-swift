import Foundation
#if canImport(lib)
    import lib
#endif

public struct KeyData: Decodable {
    let id: String
    let privateKey: String
    let type: String
}

public final class PrivateKeysModule {

    private static func set_private_key(thresholdKey: ThresholdKey, key: String?, format: String,
                                        completion: @escaping (Result<Bool, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)
                var keyPointer: UnsafeMutablePointer<Int8>?
                if key != nil {
                    keyPointer = UnsafeMutablePointer<Int8>(mutating: (key! as NSString).utf8String)
                }
                let formatPointer = UnsafeMutablePointer<Int8>(mutating: (format as NSString).utf8String)
                let result = withUnsafeMutablePointer(to: &errorCode, { error in
                    private_keys_set_private_key(thresholdKey.pointer, keyPointer, formatPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in PrivateKeysModule, private_keys_set_private_keys")
                    }
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Sets an extra private key on an existing `ThresholdKey` object.
    /// - Parameters:
    ///   - thresholdKey: The threshold key to act on.
    ///   - key: The private key to set in hexadecimal format. Optional, will be generated on the Secp256k1 curve
    ///   if not supplied.
    ///   - format: "secp256k1n" is currently the only cupported format.
    ///
    /// - Returns: `true` if key was set, `false` otherwise.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func set_private_key(thresholdKey: ThresholdKey, key: String?, format: String )
    async throws -> Bool {
        return try await withCheckedThrowingContinuation {
            continuation in
            set_private_key(thresholdKey: thresholdKey, key: key, format: format) {
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

    /// Returns stored extra private keys on an existing `ThresholdKey` object.
    /// - Parameters:
    ///   - thresholdKey: The threshold key to act on.
    ///
    /// - Returns: Array of `KeyData`.
    ///
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func get_private_keys(thresholdKey: ThresholdKey) throws -> [KeyData] {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            private_keys_get_private_keys(thresholdKey.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKeysModule, private_keys_get_private_keys")
            }
        let json = String.init(cString: result!)
        let jsonData = json.data(using: String.Encoding.utf8)!
        let keys: [KeyData] = try JSONDecoder().decode([KeyData].self, from: jsonData)
        string_free(result)
        return keys
    }

    /// Returns accounts of stored extra private keys on an existing `ThresholdKey` object.
    /// - Parameters:
    ///   - thresholdKey: The threshold key to act on.
    ///
    /// - Returns: Array of `String`.
    ///
    /// - Throws: `RuntimeError`, indicates invalid threshold key.
    public static func get_private_key_accounts(thresholdKey: ThresholdKey) throws -> [String] {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            private_keys_get_accounts(thresholdKey.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKeysModule, private_keys_get_accounts")
            }
        let json = String.init(cString: result!)
        string_free(result)
        guard let accountArray = try JSONSerialization.jsonObject(with: json.data(using: String.Encoding.utf8)!, options: .allowFragments) as? [String] else {
            throw RuntimeError("Json serialization error")
        }
        return accountArray
    }

}
