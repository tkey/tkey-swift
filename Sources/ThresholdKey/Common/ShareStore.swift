import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareStore {
    private(set) var pointer: OpaquePointer?
    
    /// Instantiate a `ShareStore` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `ShareStore`
    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    /// Instantiate a `ShareStore` object using its' corresponding json.
    ///
    /// - Parameters:
    ///   - json: Json representation as a `String`.
    ///
    /// - Returns: `ShareStore`
    ///
    /// - Throws: `RuntimeError`, json is invalid.
    public init(json: String) throws {
        var errorCode: Int32 = -1
        let jsonPointer = UnsafeMutablePointer<Int8>(mutating: (json as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_from_json(jsonPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore, json")
            }
        pointer = result
    }

    /// Serialize a `ShareStore` object to its' corresponding json.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, underlying pointer is invalid
    public func toJsonString() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_to_json(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore toJsonString")
        }
        let string = String(cString: result!)
        string_free(result)
        return string
    }

    /// Returns the Share contained in the `ShareStore` object.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, underlying pointer is invalid
    public func share() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_get_share(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore, share")
            }
        let value = String.init(cString: result!)
        string_free(result)
        return value
    }

    /// Returns the share index of the Share contained in the `ShareStore` object.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, underlying pointer is invalid
    public func share_index() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_get_share_index(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore, share index")
            }
        let value = String.init(cString: result!)
        string_free(result)
        return value
    }

    /// Returns the polynomial ID of the `ShareStore` object.
    ///
    /// - Returns: `String`
    ///
    /// - Throws: `RuntimeError`, underlying pointer is invalid
    public func polynomial_id() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_get_polynomial_id(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore, polynomial id")
            }
        let value = String.init(cString: result!)
        string_free(result)
        return value
    }

    deinit {
        share_store_free(pointer)
    }
}
