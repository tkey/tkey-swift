import Foundation
#if canImport(lib)
import lib
#endif

public final class PublicPolynomial {
    private(set) var pointer: OpaquePointer?
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

    /// Instantiate a `PublicPolynomial` object using the underlying pointer.
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

    /// Threshold for the `PublicPolynomial`.
    ///
    /// - Returns: `UInt32`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public func getThreshold() throws -> UInt32 {
        var errorCode: Int32  = -1

        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            public_polynomial_get_threshold(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Public Polynomial, get threshold")
        }
        return result
    }

    /// Returns the `KeyPoint` at the respective share index.
    /// - Parameters:
    ///   - index: Share index to be used.
    ///
    /// - Returns: `KeyPoint`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public func polyCommitmentEval(index: String) throws -> KeyPoint {
        var errorCode: Int32  = -1

        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (index as NSString).utf8String)

        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            public_polynomial_poly_commitment_eval(self.pointer, indexesPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PublicPolynomial, polyCommitmentEval")
        }
        return KeyPoint(pointer: result!)
    }

    deinit {
        public_polynomial_free(pointer)
    }
}
