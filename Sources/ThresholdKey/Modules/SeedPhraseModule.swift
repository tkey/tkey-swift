import Foundation
#if canImport(lib)
    import lib
#endif

public struct SeedPhrase: Codable {
    public var seedPhrase: String
    public var type: String
}

public final class SeedPhraseModule {
    private static func set_seed_phrase(threshold_key: ThresholdKey, format: String, phrase: String?, number_of_wallets: UInt32, completion: @escaping (Result<Void, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                let formatPointer = UnsafeMutablePointer<Int8>(mutating: (format as NSString).utf8String)
                var phrasePointer: UnsafeMutablePointer<Int8>?
                if phrase != nil {
                    phrasePointer = UnsafeMutablePointer<Int8>(mutating: (phrase! as NSString).utf8String)
                }

                withUnsafeMutablePointer(to: &errorCode, { error in
                    seed_phrase_set_phrase(threshold_key.pointer, formatPointer, phrasePointer, number_of_wallets, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error SeedPhraseModule, set_seed_phrase")
                    }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Sets a seed phrase on the metadata of a `ThresholdKey` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - format: "HD Key Tree" is the only supported format.
    ///   - phrase: The seed phrase. Optional, will be generated if not provided.
    ///   - number_of_wallets: Number of children derived from this seed phrase.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func set_seed_phrase(threshold_key: ThresholdKey, format: String, phrase: String?, number_of_wallets: UInt32 ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            set_seed_phrase(threshold_key: threshold_key, format: format, phrase: phrase, number_of_wallets: number_of_wallets) {
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
    
    private static func change_phrase(threshold_key: ThresholdKey, old_phrase: String, new_phrase: String, completion: @escaping (Result<Void, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let oldPointer = UnsafeMutablePointer<Int8>(mutating: (old_phrase as NSString).utf8String)
                let newPointer = UnsafeMutablePointer<Int8>(mutating: (new_phrase as NSString).utf8String)
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    seed_phrase_change_phrase(threshold_key.pointer, oldPointer, newPointer, curvePointer, error)
                        })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in SeedPhraseModule, change_phrase")
                    }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Replaces an old seed phrase with a new seed phrase on a `ThresholdKey` object. Same format of seed phrase must be used.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - old_phrase: The original seed phrase.
    ///   - new_phrase: The replacement phrase.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func change_phrase(threshold_key: ThresholdKey, old_phrase: String, new_phrase: String ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            change_phrase(threshold_key: threshold_key, old_phrase: old_phrase, new_phrase: new_phrase) {
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

    /// Returns the seed phrases stored on a `ThresholdKey` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///
    /// - Returns: Array of SeedPhrase objects.
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func get_seed_phrases(threshold_key: ThresholdKey) throws -> [SeedPhrase] {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            seed_phrase_get_seed_phrases(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SeedPhraseModule, get_seed_phrases")
            }
        let string = String.init(cString: result!)
        string_free(result)
        let decoder = JSONDecoder()
        let seed_array = try! decoder.decode( [SeedPhrase].self, from: string.data(using: String.Encoding.utf8)! )
        return seed_array
    }

    
    private static func delete_seed_phrase(threshold_key: ThresholdKey, phrase: String, completion: @escaping (Result<Void, Error>) -> Void) {
        threshold_key.tkeyQueue.async {
            do {
                let phrasePointer = UnsafeMutablePointer<Int8>(mutating: (phrase as NSString).utf8String)

                var errorCode: Int32 = -1
                withUnsafeMutablePointer(to: &errorCode, { error in
                    seed_phrase_delete_seed_phrase(threshold_key.pointer, phrasePointer, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("PrivateKeyModule, delete_seedphrase")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Deletes a seed phrase stored on a `ThresholdKey` object.
    /// - Parameters:
    ///   - threshold_key: The threshold key to act on.
    ///   - phrase: The phrase to be deleted.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func delete_seed_phrase(threshold_key: ThresholdKey, phrase: String ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            delete_seed_phrase(threshold_key: threshold_key, phrase: phrase) {
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
    
    /*
    static func get_seed_phrases_with_accounts(threshold_key: ThresholdKey, derivation_format: String) throws -> String
    {
        var errorCode: Int32 = -1
        let derivationPointer = UnsafeMutablePointer<Int8>(mutating: (derivation_format as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            seed_phrase_get_seed_phrases_with_accounts(threshold_key.pointer, derivationPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SeedPhraseModule, get_seed_phrases_with_accounts")
            }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
    */

    /*
    static func get_accounts(threshold_key: ThresholdKey, derivation_format: String) throws -> String
    {
        var errorCode: Int32 = -1
        let derivationPointer = UnsafeMutablePointer<Int8>(mutating: (derivation_format as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            seed_phrase_get_accounts(threshold_key.pointer, derivationPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SeedPhraseModule, get_accounts")
            }
        let string = String.init(cString: result!)
        string_free(result)
        return string
    }
    */
}
