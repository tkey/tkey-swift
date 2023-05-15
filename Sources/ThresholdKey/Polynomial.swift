import Foundation
#if canImport(lib)
import lib
#endif

public final class Polynomial {
    private(set) var pointer: OpaquePointer?
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
    
    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    public func getPublicPolynomial() throws -> PublicPolynomial {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            polynomial_get_public_polynomial(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in getPublicPolynomial")
        }
        return PublicPolynomial.init(pointer: result!);
    }
    
    public func generateShares(share_index: String) throws -> ShareMap {
        var errorCode: Int32  = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (share_index as NSString).utf8String)
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            polynomial_generate_shares(self.pointer, indexesPointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Polynomial, generateShares")
        }
        return try! ShareMap.init(pointer: result!);
    }
    deinit {
        polynomial_free(pointer);
    }
}

