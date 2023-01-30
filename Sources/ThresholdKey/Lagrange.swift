
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

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! JSONSerialization.data(withJSONObject: points_arr, options: .prettyPrinted)
        let point_string = String(data: data, encoding: String.Encoding.utf8) ?? ""

        let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
        
        let pointString = UnsafeMutablePointer<Int8>(mutating: (point_string as NSString).utf8String);
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)

        let poly_result = withUnsafeMutablePointer(to: &errorCode, { error in
            lagrange_interpolate_polynomial(pointString, curvePointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in lagrange method")
        }
        return Polynomial.init(pointer: poly_result!);
    }
}
