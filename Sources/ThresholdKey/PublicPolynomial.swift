////
////  File.swift
////
////
////  Created by guru ramu on 11/01/23.
////
//
import Foundation
#if canImport(lib)
import lib
#endif

public final class PublicPolynomial {
    private(set) var pointer: OpaquePointer?
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

    public init(pointer: OpaquePointer) throws {
        self.pointer = pointer;
    }

    public func getThreshold() throws -> UInt32  {
        var errorCode: Int32  = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            public_polynomial_get_threshold(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Public Polynomial, get threshold")
        }
        return result;
    }

    public func polyCommitmentEval(index: String) throws -> KeyPoint {
        var errorCode: Int32  = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (index as NSString).utf8String)
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            public_polynomial_poly_commitment_eval(self.pointer, indexesPointer,curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in polyCommitmentEval")
        }
        let point = try! KeyPoint(pointer: result!);
        return point;
    }
    deinit {
        public_polynomial_free(pointer);
    }
}

