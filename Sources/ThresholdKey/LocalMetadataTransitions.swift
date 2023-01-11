//
//  LocalMetadataTransitions.swift
//  
//
//  Created by David Main on 2023/01/11.
//

import Foundation

#if canImport(lib)
    import lib
#endif

public final class LocalMetadataTransitions {
    private(set) var pointer: OpaquePointer?

    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        local_metadata_transitions_free(pointer)
    }
}
