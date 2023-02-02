//
//  File.swift
//  
//
//  Created by guru ramu on 01/02/23.
//

import Foundation

#if canImport(lib)
    import lib
#endif

public class KeyPointArray {
    private(set) var pointer: OpaquePointer?
    
    public init() throws {
        var errorCode: Int32 = -1
        
        let points = withUnsafeMutablePointer(to: &errorCode, { _ in
            key_point_array_new()
        });
        self.pointer = points;
    }

    public init(point_arr: [KeyPoint]) throws {
        var errorCode: Int32 = -1
        
        let points = withUnsafeMutablePointer(to: &errorCode, { _ in
            key_point_array_new()
        });
        for point in point_arr {
            let x_ptr = UnsafeMutablePointer<Int8>(mutating: (point.x as NSString).utf8String)
            let y_ptr = UnsafeMutablePointer<Int8>(mutating: (point.y as NSString).utf8String)
            
            let point_ptr = withUnsafeMutablePointer(to: &errorCode, { error in
                key_point_new(x_ptr, y_ptr, error)
            })
            guard errorCode == 0 else {
                throw RuntimeError("Error in KeyPointArray, key_point_new")
            }
            withUnsafeMutablePointer(to: &errorCode, { error in
                key_point_array_insert(points, point_ptr, error)
            })
            guard errorCode == 0 else {
                throw RuntimeError("Error in KeyPointArray, key_point_array_insert")
            }
        }
        self.pointer = points;
    }
    
    public func removeKeyPoint(index: Int32) throws {
        var errorCode: Int32  = -1
        
        withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_remove(pointer, index, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_remove")
        }
        
    }
    
    public func insertKeyPoint(point: KeyPoint) throws {
        var errorCode: Int32 = -1
        
        let x_ptr = UnsafeMutablePointer<Int8>(mutating: (point.x as NSString).utf8String)
        let y_ptr = UnsafeMutablePointer<Int8>(mutating: (point.y as NSString).utf8String)
        
        let point_ptr = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_new(x_ptr, y_ptr, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_new")
        }
        withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_insert(pointer, point_ptr, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_insert")
        }
        
    }
    
    public func udpateKeyPoint(point: KeyPoint, index: Int32) throws {
        var errorCode: Int32 = -1
        
        let x_ptr = UnsafeMutablePointer<Int8>(mutating: (point.x as NSString).utf8String)
        let y_ptr = UnsafeMutablePointer<Int8>(mutating: (point.y as NSString).utf8String)
        
        let point_ptr = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_new(x_ptr, y_ptr, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_new")
        }
        withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_update_at_index(pointer, index, point_ptr, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_update_at_index")
        }
        
    }
    
    public func getKeyPointOnIndex(index: Int32) throws -> KeyPoint {
        var errorCode: Int32 = -1
        
        let key_point = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_get_value_by_index(pointer, index, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_get_value_by_index")
        }
        return try! KeyPoint.init(pointer: key_point!);
    }
    
    public func getKeyPointArrayLength() throws -> Int32{
        var errorCode: Int32 = -1
        
        let key_point_array_length = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_array_get_len(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_get_len")
        }
        return key_point_array_length;

    }
    
    deinit {
        key_point_array_free(pointer)
    }
}
