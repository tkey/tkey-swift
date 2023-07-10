import Foundation

#if canImport(lib)
    import lib
#endif

public class ShareStoreArray {
    private(set) var pointer: OpaquePointer?

    /// Instantiate a `ShareStoreArray` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `ShareStoreArray`
    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    /// Retrieves a `ShareStore` in the collection at a specified index.
    ///
    /// - Parameters:
    ///   - index: index of `ShareStore` to be retrieved.
    ///
    /// - Returns: `ShareStore`
    ///
    /// - Throws: `RuntimeError`, indicates invalid index or invalid `KeyPointArray`.
    public func getAt(index: Int32) throws -> ShareStore {
        var errorCode: Int32 = -1
        
        let share_store = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_array_get_value_by_index(pointer, index, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_get_value_by_index")
        }
        return ShareStore.init(pointer: share_store!);
    }
    
    /// Returns the number of items in the collection.
    ///
    /// - Returns: `Int32`
    ///
    /// - Throws: `RuntimeError`, indicates invalid `ShareStoreArray`.
    public func length() throws -> Int32{
        var errorCode: Int32 = -1
        
        let share_stores_array_length = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_array_get_len(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_get_len")
        }
        return share_stores_array_length;
    }
    
    deinit {
        share_store_array_free(pointer)
    }
}
