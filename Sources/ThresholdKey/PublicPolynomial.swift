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
    public let pointer: OpaquePointer?

    public init(pointer: OpaquePointer?) throws {
        var errorCode: Int32 = -1
  
        let publicPolynomial = withUnsafeMutablePointer(to: &errorCode, { error in
            polynomial_get_public_polynomial(pointer, error)
       })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Pub Polynomial, init")
            }
        self.pointer = publicPolynomial;
    }
    public func getThreshold() throws -> UInt32  {
        var errorCode: Int32  = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            public_polynomial_get_threshold(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in get threshold")
        }
        return result;
    }
    public func getPolynomialId() throws -> String {
        var errorCode: Int32  = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            public_polynomial_get_polynomial_id(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in getPolynomialId")
        }
        return String.init(cString: result!)
    }
    public func polyCommitmentEval(curve_n: String, index: String) throws -> KeyPoint {
        var errorCode: Int32  = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
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

