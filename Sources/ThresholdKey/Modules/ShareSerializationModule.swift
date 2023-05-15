import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareSerializationModule {
    public static func serialize_share(threshold_key: ThresholdKey, share: String, format: String? = nil) throws -> String {
        var errorCode: Int32 = -1
        
        let sharePointer = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)
        
        var formatPointer: UnsafeMutablePointer<Int8>?
        if format != nil {
            formatPointer = UnsafeMutablePointer<Int8>(mutating: (format! as NSString).utf8String)
        }

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_serialization_serialize_share(threshold_key.pointer, sharePointer, formatPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error ShareSerializationModule, serialize_share")
            }
        let value = String.init(cString: result!)
        string_free(result)
        return value
    }

    public static func deserialize_share(threshold_key: ThresholdKey, share: String, format: String? = nil) throws -> String {
        var errorCode: Int32 = -1
        
        let sharePointer = UnsafeMutablePointer<Int8>(mutating: (share as NSString).utf8String)
        
        var formatPointer: UnsafeMutablePointer<Int8>?
        if format != nil {
            formatPointer = UnsafeMutablePointer<Int8>(mutating: (format! as NSString).utf8String)
        }

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_serialization_deserialize_share(threshold_key.pointer, sharePointer, formatPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error ShareSerializationModule, deserialize_share")
            }
        let value = String.init(cString: result!)
        string_free(result)
        return value
    }
}
