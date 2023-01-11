//
//  ServiceProvider.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public final class ServiceProvider {
    private(set) var pointer: OpaquePointer?
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    public init(enable_logging: Bool, postbox_key: String) throws {
        var errorCode: Int32 = -1
        let postboxPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: postbox_key).utf8String)
        let curve = UnsafeMutablePointer<Int8>(mutating: NSString(string: curveN).utf8String)
        let result: OpaquePointer? = withUnsafeMutablePointer(to: &errorCode, { error in
            service_provider(enable_logging, postboxPointer, curve, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ServiceProvider")
            }
        pointer = result!
    }

    deinit {
        service_provider_free(pointer)
    }
}
