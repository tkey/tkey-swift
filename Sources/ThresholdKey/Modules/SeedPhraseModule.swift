import Foundation
#if canImport(lib)
    import lib
#endif

public struct SeedPhrase: Codable {
    public var seedPhrase: String
    public var type: String
}

public final class SeedPhraseModule {
    private static func set_seed_phrase(thresholdKey: ThresholdKey, format: String, phrase: String?, numberOfWallets: UInt32, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)
                let formatPointer = UnsafeMutablePointer<Int8>(mutating: (format as NSString).utf8String)
                var phrasePointer: UnsafeMutablePointer<Int8>?
                if phrase != nil {
                    phrasePointer = UnsafeMutablePointer<Int8>(mutating: (phrase! as NSString).utf8String)
                }

                withUnsafeMutablePointer(to: &errorCode, { error in
                    seed_phrase_set_phrase(thresholdKey.pointer, formatPointer, phrasePointer, numberOfWallets, curvePointer, error)
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
    ///   - thresholdKey: The threshold key to act on.
    ///   - format: "HD Key Tree" is the only supported format.
    ///   - phrase: The seed phrase. Optional, will be generated if not provided.
    ///   - number_of_wallets: Number of children derived from this seed phrase.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func set_seed_phrase(thresholdKey: ThresholdKey, format: String, phrase: String?, numberOfWallets: UInt32 ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            set_seed_phrase(thresholdKey: thresholdKey, format: format, phrase: phrase, numberOfWallets: numberOfWallets) {
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

    private static func change_phrase(thresholdKey: ThresholdKey, oldPhrase: String, newPhrase: String, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                var errorCode: Int32 = -1
                let oldPointer = UnsafeMutablePointer<Int8>(mutating: (oldPhrase as NSString).utf8String)
                let newPointer = UnsafeMutablePointer<Int8>(mutating: (newPhrase as NSString).utf8String)
                let curvePointer = UnsafeMutablePointer<Int8>(mutating: (thresholdKey.curveN as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    seed_phrase_change_phrase(thresholdKey.pointer, oldPointer, newPointer, curvePointer, error)
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
    ///   - thresholdKey: The threshold key to act on.
    ///   - old_phrase: The original seed phrase.
    ///   - new_phrase: The replacement phrase.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func change_phrase(thresholdKey: ThresholdKey, oldPhrase: String, newPhrase: String ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            change_phrase(thresholdKey: thresholdKey, oldPhrase: oldPhrase, newPhrase: newPhrase) {
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
    ///   - thresholdKey: The threshold key to act on.
    ///
    /// - Returns: Array of SeedPhrase objects.
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func get_seed_phrases(thresholdKey: ThresholdKey) throws -> [SeedPhrase] {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            seed_phrase_get_seed_phrases(thresholdKey.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in SeedPhraseModule, get_seed_phrases")
            }
        let string = String.init(cString: result!)
        string_free(result)
        let decoder = JSONDecoder()
        guard let data = string.data(using: String.Encoding.utf8) else {
            throw RuntimeError("String to data error")
        }
        let seedArray = try decoder.decode( [SeedPhrase].self, from: data )
        return seedArray
    }

    private static func delete_seed_phrase(thresholdKey: ThresholdKey, phrase: String, completion: @escaping (Result<Void, Error>) -> Void) {
        thresholdKey.tkeyQueue.async {
            do {
                let phrasePointer = UnsafeMutablePointer<Int8>(mutating: (phrase as NSString).utf8String)

                var errorCode: Int32 = -1
                withUnsafeMutablePointer(to: &errorCode, { error in
                    seed_phrase_delete_seed_phrase(thresholdKey.pointer, phrasePointer, error)
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
    ///   - thresholdKey: The threshold key to act on.
    ///   - phrase: The phrase to be deleted.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func delete_seed_phrase(thresholdKey: ThresholdKey, phrase: String ) async throws {
        return try await withCheckedThrowingContinuation {
            continuation in
            delete_seed_phrase(thresholdKey: thresholdKey, phrase: phrase) {
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
    static func get_seed_phrases_with_accounts(thresholdKey: ThresholdKey, derivation_format: String) throws -> String
    {
        var errorCode: Int32 = -1
        let derivationPointer = UnsafeMutablePointer<Int8>(mutating: (derivation_format as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            seed_phrase_get_seed_phrases_with_accounts(thresholdKey.pointer, derivationPointer, error)
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
    static func get_accounts(thresholdKey: ThresholdKey, derivation_format: String) throws -> String
    {
        var errorCode: Int32 = -1
        let derivationPointer = UnsafeMutablePointer<Int8>(mutating: (derivation_format as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            seed_phrase_get_accounts(thresholdKey.pointer, derivationPointer, error)
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
