//
//  File.swift
//  
//
//  Created by guru ramu on 13/01/23.
//


import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareMap {
    private(set) var pointer: OpaquePointer?

    public init(pointer: OpaquePointer) throws {
        self.pointer = pointer
    }

    public func getShareIndexes() throws -> String {
        var errorCode: Int32 = -1
        let keys = withUnsafeMutablePointer(to: &errorCode, { error in
            share_map_get_share_keys(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareMap, getShareIndexes")
        }
        let shareIndexes = String.init(cString: keys!)
        return shareIndexes
    }

    public func getShareByKey() throws -> String {
        var errorCode: Int32 = -1
        let values = withUnsafeMutablePointer(to: &errorCode, { error in
            share_map_get_share_by_key(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ShareMap, getShareIndexes")
        }
        let share = String.init(cString: values!)
        return share
    }
    
    deinit {
        share_map_free(pointer);
    }
}

