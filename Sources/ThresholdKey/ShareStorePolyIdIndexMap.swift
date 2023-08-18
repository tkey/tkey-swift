import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareStorePolyIdIndexMap {
    private(set) var pointer: OpaquePointer
    public var shareMaps = [String: ShareStoreMap]()

    /// Instantiate a `ShareStorePolyIdIndexMap` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `ShareStorePolyIdIndexMap`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public init(pointer: OpaquePointer) throws {
        var errorCode: Int32 = -1
        let keys = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_poly_id_index_map_get_keys(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStorePolyIdIndexMap")
            }
        let value = String.init(cString: keys!)
        string_free(keys)
        let data = Data(value.utf8)
        guard let keyArray = try JSONSerialization.jsonObject(with: data) as? [String] else {
            throw RuntimeError("Json serialization Error")
        }
        for item in keyArray {
            let keyPointer = UnsafeMutablePointer<Int8>(mutating: (item as NSString).utf8String)
            let value = withUnsafeMutablePointer(to: &errorCode, { error -> OpaquePointer? in
                share_store_poly_id_index_map_get_value_by_key(pointer, keyPointer, error)
                    })
            guard errorCode == 0 else {
                throw RuntimeError("Error in ShareStorePolyIdIndexMap")
                }
            shareMaps[item] = try ShareStoreMap.init(pointer: value!)
        }

        self.pointer = pointer
    }

    deinit {
        share_store_poly_id_index_map_free(pointer)
    }

    // TODO: Class requires a init(json: String) throws method and an export() throws -> String method.
}
