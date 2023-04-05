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

public class ShareStoreArray {
    private(set) var pointer: OpaquePointer?

    public init(pointer: OpaquePointer) throws {
        self.pointer = pointer
    }
    
    public func getAt(index: Int32) throws -> ShareStore {
        var errorCode: Int32 = -1
        
        let share_store = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_array_get_value_by_index(pointer, index, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_get_value_by_index")
        }
        return ShareStore.init(pointer: share_store!);
    }
    
    public func length() throws -> Int32{
        var errorCode: Int32 = -1
        
        let share_stores_array_length = withUnsafeMutablePointer(to: &errorCode, { error in
            share_store_array_get_len(pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPointArray, key_point_array_get_len")
        }
        return share_stores_array_length;
    }
    
    deinit {
        share_store_array_free(pointer)
    }
}
