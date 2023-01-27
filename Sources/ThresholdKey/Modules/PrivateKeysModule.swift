//
//  PrivateKeysModule.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation
#if canImport(lib)
    import lib
#endif

public final class PrivateKeysModule {
    public static func set_private_key(threshold_key: ThresholdKey, key: String?, format: String) throws -> Bool {
        var errorCode: Int32 = -1
        let curvePointer = UnsafeMutablePointer<Int8>(mutating: (threshold_key.curveN as NSString).utf8String)
        var keyPointer: UnsafeMutablePointer<Int8>?
        if key != nil {
            keyPointer = UnsafeMutablePointer<Int8>(mutating: (key! as NSString).utf8String)
        }
        let formatPointer = UnsafeMutablePointer<Int8>(mutating: (format as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            private_keys_set_private_key(threshold_key.pointer, keyPointer, formatPointer, curvePointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKeysModule, private_keys_set_private_keys")
            }
        return result
    }

    public static func get_private_keys(threshold_key: ThresholdKey) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            private_keys_get_private_keys(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKeysModule, private_keys_get_private_keys")
            }
        let json = String.init(cString: result!)
        string_free(result)
        return json
    }

    public static func get_private_key_accounts(threshold_key: ThresholdKey) throws -> [String] {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            private_keys_get_accounts(threshold_key.pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in PrivateKeysModule, private_keys_get_accounts")
            }
        let json = String.init(cString: result!)
        string_free(result)
        let account_array = try! JSONSerialization.jsonObject(with: json.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [String]
        return account_array
    }

}