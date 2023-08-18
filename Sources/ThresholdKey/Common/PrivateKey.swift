import Foundation
#if canImport(lib)
    import lib
#endif

public final class PrivateKey {
    public var hex: String
    internal static let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

    /// Instantiate a `PrivateKey` object using the underlying pointer.
    /// 
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `PrivateKey` object.
    public init(pointer: UnsafeMutablePointer<Int8>) {
        hex = String.init(cString: pointer)
        string_free(pointer)
    }

    /// Instantiates a `PrivateKey` object from its' serialized format.
    ///
    /// - Parameters:
    ///   - hex: hexadecimal representation as `String`
    ///
    /// - Returns: `PrivateKey` object.
    public init(hex: String) {
        self.hex = hex
    }

    public func toPublic (format: PublicKeyEncoding = .ellipticCompress ) throws -> String {
        var errorCode: Int32 = -1
        let secretPointer = UnsafeMutablePointer<Int8>(mutating: (self.hex as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            private_to_public(secretPointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKey, generate")
        }
        let publicHex = String.init(cString: result!)
        string_free(result)

        let publicKey = try KeyPoint(address: publicHex).getPublicKey(format: format )
        return publicKey
    }

    /// Instantiates a `PrivateKey` object by random generation.
    ///
    /// - Returns: `PrivateKey` object.
    ///
    /// - Throws: `RuntimeError`, only possible if curveN is passed externally.
    public static func generate() throws -> PrivateKey {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            generate_private_key(curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKey, generate")
            }
        return PrivateKey.init(pointer: result!)
    }
}
