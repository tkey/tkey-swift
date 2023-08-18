import Foundation
#if canImport(lib)
    import lib
#endif

public final class GenerateShareStoreResult {
    private(set) var pointer: OpaquePointer?
    public var hex: String
    public var shareStore: ShareStoreMap

    /// Instantiate a `GenerateShareStoreResult` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `GenerateShareStoreResult`
    ///
    ///   - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public init(pointer: OpaquePointer) throws {
        self.pointer = pointer
        var errorCode: Int32 = -1
        let hexPtr = withUnsafeMutablePointer(to: &errorCode, { error in
            generate_new_share_store_result_get_shares_index(pointer, error)
                })
        guard errorCode == 0 else {
        throw RuntimeError("Error in GenerateShareStoreResult, field hex")
        }
        hex = String.init(cString: hexPtr!)
        string_free(hexPtr)
        let storePtr = withUnsafeMutablePointer(to: &errorCode, { error in
           generate_new_share_store_result_get_share_store_map(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in GenerateShareStoreResult, field share_store")
            }
        shareStore = try ShareStoreMap.init(pointer: storePtr!)
    }

    deinit {
        generate_share_store_result_free(pointer)
    }
}
