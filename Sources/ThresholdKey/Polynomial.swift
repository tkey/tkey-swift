//
//  File.swift
//  
//
//  Created by guru ramu on 11/01/23.
//

import Foundation
#if canImport(lib)
import lib
#endif

public final class Polynomial {
    public let pointer: OpaquePointer?
//    public let publicPolynomial: PublicPolynomial

    public init(pointer: OpaquePointer, curve_n: String) throws {
        var errorCode: Int32 = -1
        let curve = UnsafeMutablePointer<Int8>(mutating: NSString(string: curve_n).utf8String)

        let polynomial = withUnsafeMutablePointer(to: &errorCode, { error in
//           key_details_get_pub_key_point(pointer, error)
            threshold_reconstruct_latest_poly(pointer, curve, error)
           })
        guard errorCode == 0 else {
            throw RuntimeError("Error in Polynomial, init")
            }
        self.pointer = polynomial;
    }
    
    public func getPublicPolynomial() throws -> PublicPolynomial {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            polynomial_get_public_polynomial(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in getPublicPolynomial")
        }
        let publicPolynomial = try! PublicPolynomial(pointer: result);
        return publicPolynomial
        
    }
    
    public func getPolynomialId() throws -> String {
        var errorCode: Int32  = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            polynomial_get_polynomial_id(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in getPolynomialId")
        }
        return String.init(cString: result!)
    }
    
    public func generateShares(curve_n: String, share_index: String) throws -> OpaquePointer? {
        var errorCode: Int32  = -1
        
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curve_n as NSString).utf8String)
        let indexesPointer = UnsafeMutablePointer<Int8>(mutating: (share_index as NSString).utf8String)
        
        let result = withUnsafeMutablePointer(to: &errorCode, {error in
            polynomial_generate_shares(self.pointer, curvePointer, indexesPointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in generateShares")
        }
        return result;
    }
    deinit {
        polynomial_free(pointer);
    }
}

