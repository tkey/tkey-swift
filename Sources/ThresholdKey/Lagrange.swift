
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
        
        let points = withUnsafeMutablePointer(to: &errorCode, { _ in
            key_point_array_new()
        });
        for point in points_arr {
            let x_ptr = UnsafeMutablePointer<Int8>(mutating: (point.x as NSString).utf8String)
            let y_ptr = UnsafeMutablePointer<Int8>(mutating: (point.y as NSString).utf8String)
            
            let point_ptr = withUnsafeMutablePointer(to: &errorCode, { error in
                point_new(x_ptr, y_ptr, error)
            })
            guard errorCode == 0 else {
                throw RuntimeError("Error in Lagrange, creating point_new method")
            }
            withUnsafeMutablePointer(to: &errorCode, { error in
                key_point_array_insert(points, point_ptr, error)
            })
            guard errorCode == 0 else {
                throw RuntimeError("Error in Lagrange, inserting points method")
            }
        }
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)

        let poly_result = withUnsafeMutablePointer(to: &errorCode, { error in
            lagrange_interpolate_polynomial(points, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in lagrange, lagrange_interpolate_polynomial method")
        }
        return Polynomial.init(pointer: poly_result!);
    }
}
