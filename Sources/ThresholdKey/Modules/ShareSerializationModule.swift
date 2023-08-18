import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareSerializationModule {
    /// Serializes a share on a `Threshold Key` object.
    /// - Parameters:
    ///   - thresholdkey: The threshold key to act on.
    ///   - format: Optional, can either be nil or `"mnemonic"`.
    ///   - share: Share to be serialized.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func serialize_share(thresholdkey: ThresholdKey, share: String, format: String? = nil) throws -> String {
        var errorCode: Int32 = -1

        let sharePointer = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)

        var formatPointer: UnsafeMutablePointer<Int8>?
        if format != nil {
            formatPointer = UnsafeMutablePointer<Int8>(mutating: (format! as NSString).utf8String)
        }

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_serialization_serialize_share(thresholdkey.pointer, sharePointer, formatPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error ShareSerializationModule, serialize_share")
            }
        let value = String.init(cString: result!)
        string_free(result)
        return value
    }

    /// Deserialize a share on a `Threshold Key` object.
    /// - Parameters:
    ///   - thresholdkey: The threshold key to act on.
    ///   - format: Optional, can either be nil or `"mnemonic"`.
    ///   - share: Share to be serialized.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used or invalid threshold key.
    public static func deserialize_share(thresholdkey: ThresholdKey, share: String, format: String? = nil) throws -> String {
        var errorCode: Int32 = -1

        let sharePointer = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)

        var formatPointer: UnsafeMutablePointer<Int8>?
        if format != nil {
            formatPointer = UnsafeMutablePointer<Int8>(mutating: (format! as NSString).utf8String)
        }

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_serialization_deserialize_share(thresholdkey.pointer, sharePointer, formatPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error ShareSerializationModule, deserialize_share")
            }
        let value = String.init(cString: result!)
        string_free(result)
        return value
    }
}
