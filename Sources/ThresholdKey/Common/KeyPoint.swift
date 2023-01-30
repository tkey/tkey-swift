//
//  Point.swift
//  tkey_ios
//
//  Created by David Main on 2022/11/01.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public final class KeyPoint: Codable {
    public var x, y: String
    public var compressed: String
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

    public init(pointer: OpaquePointer) throws {
        var errorCode: Int32 = -1
        var result = withUnsafeMutablePointer(to: &errorCode, { error in
            point_get_x(pointer, error)
                })
        x = String.init(cString: result!)
        string_free(result)
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field X")
            }
        result = withUnsafeMutablePointer(to: &errorCode, { error in
            point_get_y(pointer, error)
                })
        y = String.init(cString: result!)
        string_free(result)
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field Y")
            }

        let encoder_format = UnsafeMutablePointer<Int8>(mutating: ("elliptic-compressed" as NSString).utf8String)
        result = withUnsafeMutablePointer(to: &errorCode, { error in
            point_encode(pointer, encoder_format, error)
        })
        if ((result) != nil) {
            compressed = String.init(cString: result!)
            string_free(result)
            guard errorCode == 0 else {
                throw RuntimeError("Error in KeyPoint, field Y")
            }
            
        } else {
            compressed = ""
        }
        

        point_free(pointer)
    }
    public static func from_json(json: String) throws -> KeyPoint {
        var errorCode: Int32 = -1
        let jsonPointer = UnsafeMutablePointer<Int8>(mutating: (json as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            point_from_json(jsonPointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareStore \(errorCode)")
            }
        return try! KeyPoint.init(pointer: result!);
    }
}
