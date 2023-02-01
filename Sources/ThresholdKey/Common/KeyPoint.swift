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
        compressed = String.init(cString: result!)
        string_free(result)
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field Y")
            }

        point_free(pointer)
    }

    public static func from_point(x: String, y: String) throws -> KeyPoint {
        var errorCode: Int32 = -1

        let x_ptr = UnsafeMutablePointer<Int8>(mutating: NSString(string: x).utf8String)
        let y_ptr = UnsafeMutablePointer<Int8>(mutating: NSString(string: y).utf8String)
        
        let point_ptr = withUnsafeMutablePointer(to: &errorCode, { error in
            point_new(x_ptr, y_ptr, error)
        })
       guard errorCode == 0 else {
           throw RuntimeError("Error in KeyPoint, from_point")
       }

        return try! KeyPoint.init(pointer: point_ptr!);
    }
}
