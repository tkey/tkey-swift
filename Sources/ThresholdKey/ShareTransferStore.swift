//
//  ShareTransferStore.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public final class ShareTransferStore {
    private(set) var pointer: OpaquePointer?

    /// Instantiate a `ShareTransferStore` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `ShareTransferStore`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        share_transfer_store_free(pointer)
    }
}
