import Foundation
#if canImport(lib)
    import lib
#endif

public enum PublicKeyEncoding: Equatable, Hashable {
    case EllipticCompress
    case FullAddress

    public var value: String {
        switch self {
        case .EllipticCompress:
            return "elliptic-compressed"
        case .FullAddress:
            return ""
        }
    }
}

public final class KeyPoint: Equatable {

    /// Compares two KeyPoint objects
    ///
    /// - Parameters:
    ///   - lhs: First `KeyPoint` to compare.
    ///   - rhs: Second `Keypoint` to compare.
    ///
    /// - Returns: `true` if they are equal, `false` otherwise
    public static func == (lhs: KeyPoint, rhs: KeyPoint) -> Bool {
        do {
            let lhsx = try lhs.getX()
            let lhsy = try lhs.getY()
            let rhsx = try rhs.getX()
            let rhsy = try rhs.getY()
            if  lhsx == rhsx && lhsy == rhsy {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }

    public var pointer: OpaquePointer?

    /// Instantiate a `KeyPoint` object using the underlying pointer.
    ///
    /// - Returns: `KeyPoint`
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    /// Instantiates a `KeyPoint` object using X and Y co-ordinates in hexadecimal format.
    ///
    /// - Parameters:
    ///   - x: X value of co-ordinate pair.
    ///   - y: Y value of co-ordinate pair.
    ///
    /// - Returns: `KeyPoint` object.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used.
    public init(x: String, y: String) throws {
        var errorCode: Int32 = -1
        let xPtr = UnsafeMutablePointer<Int8>(mutating: (x as NSString).utf8String)
        let yPtr = UnsafeMutablePointer<Int8>(mutating: (y as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_new(xPtr, yPtr, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, new")
            }
        pointer = result
    }

    /// Instantiates a `KeyPoint` object using X and Y co-ordinates in hexadecimal format.
    ///
    /// - Parameters:
    ///   - address : compress or full address
    ///
    /// - Returns: `KeyPoint` object.
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters was used.
    public init(address: String ) throws {
        var errorCode: Int32 = -1
        let addressPtr = UnsafeMutablePointer<Int8>(mutating: (address as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_new_addr(addressPtr, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, new")
            }
        pointer = result
    }

    /// Retrieves the X value of the co-ordinate pair.
    ///
    /// - Returns: X value in hexadecimal format as `String`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public func getX() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_get_x(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field X")
            }
        let x = String.init(cString: result!)
        string_free(result)
        return x
    }

    /// Retrieves the Y value of the co-ordinate pair.
    ///
    /// - Returns: Y value in hexadecimal format as `String`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public func getY() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_get_y(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field Y")
            }
        let y = String.init(cString: result!)
        string_free(result)
        return y
    }

    /// Gets the serialized form of a `KeyPoint`, should it be a valid PublicKey.
    ///
    /// - Parameters:
    ///   - format: `"elliptic-compressed"` for the compressed form, otherwise the uncompressed form will be returned.
    ///
    /// - Returns: Serialized form of `KeyPoint` as `String`
    ///
    /// - Throws: `RuntimeError`, indicates either the underlying pointer is invalid or the co-ordinate pair is not a valid PublicKey.
    public func getPublicKey(format: PublicKeyEncoding ) throws -> String {
        var errorCode: Int32 = -1

        let encoder_format = UnsafeMutablePointer<Int8>(mutating: (format.value as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_encode(pointer, encoder_format, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, getAsCompressedPublicKey")
            }
        let compressed = String.init(cString: result!)
        string_free(result)
        return compressed
    }

    deinit {
        key_point_free(pointer)
    }
}
