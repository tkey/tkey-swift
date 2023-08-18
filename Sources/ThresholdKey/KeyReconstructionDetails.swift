import Foundation
#if canImport(lib)
    import lib
#endif

public final class KeyReconstructionDetails: Codable {
    public var key: String
    public var seedPhrase: [String]
    public var allKeys: [String]

    /// Instantiate a `KeyReconstructionDetails` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `KeyReconstructionDetails`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public init(pointer: OpaquePointer) throws {
        var errorCode: Int32 = -1
        let key = withUnsafeMutablePointer(to: &errorCode, { error in
           key_reconstruction_get_private_key(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Private Key")
            }
        self.key = String.init(cString: key!)
        string_free(key)

        self.seedPhrase = []
        let seedLen = withUnsafeMutablePointer(to: &errorCode, { error in
           key_reconstruction_get_seed_phrase_len(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Seed Phrase")
            }
        if seedLen > 0 {
            for index in 0...seedLen-1 {
                let seedItem = withUnsafeMutablePointer(to: &errorCode, { error in
                   key_reconstruction_get_seed_phrase_at(pointer, index, error)
                       })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in KeyDetails, field Seed Phrase, index " + String(index))
                    }
                self.seedPhrase.append(String.init(cString: seedItem!))
                string_free(seedItem)
            }
        }

        self.allKeys = []
        let keysLen = withUnsafeMutablePointer(to: &errorCode, { error in
           key_reconstruction_get_all_keys_len(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Seed Phrase")
            }
        if keysLen > 0 {
            for index in 0...keysLen-1 {
                let seedItem = withUnsafeMutablePointer(to: &errorCode, { error in
                   key_reconstruction_get_all_keys_at(pointer, index, error)
                       })
                guard errorCode == 0 else {
                    throw RuntimeError("Error in KeyDetails, field Seed Phrase, index " + String(index))
                    }
                self.allKeys.append(String.init(cString: seedItem!))
                string_free(seedItem)
            }
        }

        key_reconstruction_details_free(pointer)
    }
}
