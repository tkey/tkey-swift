//
//  SeedPhraseModule.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public struct seedPhraseStruct: Codable {
    public var seedPhrase: String
    public var type: String
}

public final class SeedPhraseModule {
    public static func set_seed_phrase(threshold_key: ThresholdKey, format: String, phrase: String?, number_of_wallets: UInt32) throws {
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
    }
    
    public static func setSeedPhraseAsync(threshold_key: ThresholdKey, format: String, phrase: String?, number_of_wallets: UInt32, completion: @escaping (Result<Void, Error>) -> Void) {
        ThresholdKey.moduleQueue.async {
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

    public static func change_phrase(threshold_key: ThresholdKey, old_phrase: String, new_phrase: String) throws {
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
    }
    
    public static func changeSeedPhraseAsync(threshold_key: ThresholdKey, old_phrase: String, new_phrase: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ThresholdKey.moduleQueue.async {
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

    public static func get_seed_phrases(threshold_key: ThresholdKey) throws -> [seedPhraseStruct] {
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
        let seed_array = try! decoder.decode( [seedPhraseStruct].self, from: string.data(using: String.Encoding.utf8)! )
        return seed_array
    }

    public static func delete_seedphrase(threshold_key: ThresholdKey, phrase: String) throws {
        let phrasePointer = UnsafeMutablePointer<Int8>(mutating: (phrase as NSString).utf8String)

        var errorCode: Int32 = -1
        withUnsafeMutablePointer(to: &errorCode, { error in
            seed_phrase_delete_seed_phrase(threshold_key.pointer, phrasePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("PrivateKeyModule, set_key \(errorCode)")
        }
    }
    
    public static func deleteSeedPhraseAsync(threshold_key: ThresholdKey, phrase: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ThresholdKey.moduleQueue.async {
            do {
                var errorCode: Int32 = -1
                let phrasePointer = UnsafeMutablePointer<Int8>(mutating: (phrase as NSString).utf8String)
                withUnsafeMutablePointer(to: &errorCode, { error in
                    seed_phrase_delete_seed_phrase(threshold_key.pointer, phrasePointer, error)
                })
                guard errorCode == 0 else {
                    throw RuntimeError("PrivateKeyModule, set_key \(errorCode)")
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
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
