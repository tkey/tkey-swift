import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareStorePolyIdIndexMap {
    private(set) var pointer: OpaquePointer;
    public var share_maps = [String: ShareStoreMap]()

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
        let key_array = try JSONSerialization.jsonObject(with: data) as! [String]
        for item in key_array {
            let keyPointer = UnsafeMutablePointer<Int8>(mutating: (item as NSString).utf8String)
            let value = withUnsafeMutablePointer(to: &errorCode, { error -> OpaquePointer? in
                share_store_poly_id_index_map_get_value_by_key(pointer, keyPointer, error)
                    })
            guard errorCode == 0 else {
                throw RuntimeError("Error in ShareStorePolyIdIndexMap")
                }
            share_maps[item] = try! ShareStoreMap.init(pointer: value!)
        }

        self.pointer = pointer
    }
    
    deinit {
        share_store_poly_id_index_map_free(pointer)
    }
}
