import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareMap {
    public var share_map = [String: String]()

    /// Instantiate a `ShareMap` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `ShareMap`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public init(pointer: OpaquePointer) throws {
        var errorCode: Int32 = -1
        let keys = withUnsafeMutablePointer(to: &errorCode, { error in
            share_map_get_share_keys(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Share Map")
        }
        let value = String.init(cString: keys!)
        string_free(keys)
        let data = Data(value.utf8)
        let key_array = try JSONSerialization.jsonObject(with: data) as! [String]
        for item in key_array {
            let keyPointer = UnsafeMutablePointer<Int8>(mutating: (item as NSString).utf8String)
            let value = withUnsafeMutablePointer(to: &errorCode, { error in
                share_map_get_share_by_key(pointer, keyPointer, error)
                    })
            guard errorCode == 0 else {
                throw RuntimeError("Error in Share Map")
                }
            share_map[item] = String.init(cString: value!)
            string_free(value)
        }
        share_map_free(pointer)
    }
}
