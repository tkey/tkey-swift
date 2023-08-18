import Foundation

#if canImport(lib)
    import lib
#endif

public class KeyPointArray {
    private(set) var pointer: OpaquePointer?

    /// Instantiate a new `KeyPointArray` object.
    ///
    /// - Returns: `KeyPointArray`
    public init() {
        self.pointer = key_point_array_new()
    }

    /// Instantiate a `KeyPointArray` object using the underlying pointer.
    ///
    /// - Returns: `KeyPointArray`
    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    /// Removes a `KeyPoint` from the collection at a specified index.
    ///
    /// - Parameters:
    ///   - index: Index for removal.
    ///
    /// - Throws: `RuntimeError`, indicates invalid index or invalid `KeyPointArray`.
    public func removeAt(index: Int32) throws {
        var errorCode: Int32  = -1

        withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_remove(pointer, index, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_remove")
        }
    }

    /// Inserts a `KeyPoint` into the collection at the end.
    ///
    /// - Parameters:
    ///   - point: `KeyPoint` to be added.
    ///
    /// - Throws: `RuntimeError`, indicates invalid `KeyPoint` or invalid `KeyPointArray`.
    public func insert(point: KeyPoint) throws {
        var errorCode: Int32 = -1
        withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_insert(pointer, point.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_insert")
        }
    }

    /// Replaces a `KeyPoint` in the collection at a specified index.
    ///
    /// - Parameters:
    ///   - point: `KeyPoint` used for replacement.
    ///   - index: index of `KeyPoint` to be replaced.
    ///
    /// - Throws: `RuntimeError`, indicates invalid `KeyPoint`, index or invalid `KeyPointArray`.
    public func update(point: KeyPoint, index: Int32) throws {
        var errorCode: Int32 = -1

        withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_update_at_index(pointer, index, point.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_update_at_index")
        }
    }

    /// Retrieves a `KeyPoint` in the collection at a specified index.
    ///
    /// - Parameters:
    ///   - index: index of `KeyPoint` to be retrieved.
    ///
    /// - Returns: `KeyPoint`
    ///
    /// - Throws: `RuntimeError`, indicates invalid index or invalid `KeyPointArray`.
    public func getAt(index: Int32) throws -> KeyPoint {
        var errorCode: Int32 = -1

        let keyPoint = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_get_value_by_index(pointer, index, error)})
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_get_value_by_index")
        }
        return KeyPoint.init(pointer: keyPoint!)
    }

    /// Number of items contained in the collection.
    ///
    /// - Returns: `Int32`
    ///
    /// - Throws: `RuntimeError`, invalid `KeyPointArray`.
    public func length() throws -> Int32 {
        var errorCode: Int32 = -1

        let keyPointArrayLength = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_get_len(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_get_len")
        }
        return keyPointArrayLength

    }

    /// Performs lagrange interpolation on the items contained in the collection.
    ///
    /// - Returns: `Polynomial`
    ///
    /// - Throws: `RuntimeError`, indicates invalid `KeyPointArray`.
    public func lagrange() throws -> Polynomial {
        var errorCode: Int32 = -1

        let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)

        let polyResult = withUnsafeMutablePointer(to: &errorCode, { error in
            lagrange_interpolate_polynomial(pointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in lagrange, lagrange_interpolate_polynomial method")
        }

        return Polynomial.init(pointer: polyResult!)
    }

    deinit {
        key_point_array_free(pointer)
    }
}
