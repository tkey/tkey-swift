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
}
