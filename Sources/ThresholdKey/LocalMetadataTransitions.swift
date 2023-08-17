import Foundation

#if canImport(lib)
    import lib
#endif

public final class LocalMetadataTransitions {
    private(set) var pointer: OpaquePointer?

    /// Instantiate a `LocalMetadataTransitions` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `LocalMetadataTransitions`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    /// Instantiate a `LocalMetadataTransitions` object using the json representation.
    ///
    /// - Parameters:
    ///   - json: Json representation as `String`.
    ///
    /// - Returns: `LocalMetadataTransitions`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public init(json: String) throws {
        var errorCode: Int32 = -1
        let jsonPointer = UnsafeMutablePointer<Int8>(mutating: (json as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            local_metadata_transitions_from_json(jsonPointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore")
            }
        pointer = result
    }

    /// Serialize to json
    ///
    /// - Returns:`String`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public func export() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            local_metadata_transitions_to_json(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore")
            }
        let value = String.init(cString: result!)
        string_free(result)
        return value
    }

    deinit {
        local_metadata_transitions_free(pointer)
    }
}
