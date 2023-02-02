
//
//  Lagrange.swift
//  tkey_ios
//
//  Created by Guru Ramu on 20/01/2023.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public class Lagrange {

    public static func lagrange(points_arr: [KeyPoint]) throws -> Polynomial {
        var errorCode: Int32 = -1


        let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        
        let points = try! KeyPointArray.init(point_arr: points_arr);

        let poly_result = withUnsafeMutablePointer(to: &errorCode, { error in
            lagrange_interpolate_polynomial(points.pointer, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in lagrange, lagrange_interpolate_polynomial method")
        }
        
        return Polynomial.init(pointer: poly_result!);
    }
}
