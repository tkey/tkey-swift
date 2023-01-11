//
//  PrivateKey.swift
//  tkey_ios (iOS)
//
//  Created by David Main on 2022/11/01.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public final class PrivateKey {
    public var hex: String
    internal static let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

    public init(pointer: UnsafeMutablePointer<Int8>) {
        hex = String.init(cString: pointer)
        string_free(pointer)
    }

    public static func generate() throws -> PrivateKey {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (curveN as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            generate_private_key(curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKey, generate")
            }
        return PrivateKey.init(pointer: result!)
    }
}
