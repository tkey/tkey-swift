import Foundation
#if canImport(lib)
import lib
#endif

public final class Polynomial {
    private(set) var pointer: OpaquePointer?
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

    /// Instantiate a `Polynomial` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `Polynomial`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    /// Retrieves the corresponding `PublicPolynomial`
    ///
    ///
    /// - Returns: `PublicPolynomial`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public func getPublicPolynomial() throws -> PublicPolynomial {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            polynomial_get_public_polynomial(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in getPublicPolynomial")
        }
        return PublicPolynomial.init(pointer: result!)
    }

    /// Generates a share at the respective share index.
    ///
    /// - Parameters:
    ///   - share_index: Share index to be used.
    ///
    /// - Returns: `ShareMap`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public func generateShares(shareIndex: String) throws -> ShareMap {
        var errorCode: Int32  = -1

        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (shareIndex as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            polynomial_generate_shares(self.pointer, indexesPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Polynomial, generateShares")
        }
        return try ShareMap.init(pointer: result!)
    }

    deinit {
        polynomial_free(pointer)
    }
}
