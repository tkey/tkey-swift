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
        compressed = String.init(cString: result!)
        string_free(result)
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field Y")
            }

        point_free(pointer)
    }
    public init(x:String, y: String, compressed:String? = nil) throws {
        var errorCode: Int32 = -1
        let xPointer = UnsafeMutablePointer<Int8>(mutating: (x as NSString).utf8String)
        let yPointer = UnsafeMutablePointer<Int8>(mutating: (y as NSString).utf8String)

        let key_detail = withUnsafeMutablePointer(to: &errorCode, { error in
            point(xPointer,yPointer, error);
        });

        let result_x = withUnsafeMutablePointer(to: &errorCode, { error in
            point_get_x(key_detail, error)
        })
        self.x = String.init(cString: result_x!)
        string_free(result_x)
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field X")
        }
        
        let result_y = withUnsafeMutablePointer(to: &errorCode, { error in
            point_get_y(key_detail, error)
        })
        self.y = String.init(cString: result_y!)
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field Y")
        }
        
        if compressed != nil {
            let encoder_format = UnsafeMutablePointer<Int8>(mutating: ("elliptic-compressed" as NSString).utf8String)
            let result_compressed = withUnsafeMutablePointer(to: &errorCode, { error in
                point_encode(key_detail, encoder_format, error)
            })
            self.compressed = String.init(cString: result_compressed!)
            guard errorCode == 0 else {
                throw RuntimeError("Error in KeyPoint, field Y")
            }
        } else {
            self.compressed = ""
        }
       
        point_free(key_detail)
    }
}
