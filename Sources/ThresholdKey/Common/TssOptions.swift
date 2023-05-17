import Foundation
#if canImport(lib)
import lib
#endif

public final class TssOptions {
    private(set) var pointer: OpaquePointer?

    public init(input_tss_share: String, tss_input_index: Int32, auth_signatures: String, factor_pub: KeyPoint, selected_servers: String? = nil, new_tss_index: Int32? = nil, new_factor_pub: KeyPoint? = nil) throws {
        var errorCode: Int32 = -1
        let inputSharePointer = UnsafeMutablePointer<Int8>(mutating: (input_tss_share as NSString).utf8String)
        let authSignaturesPointer = UnsafeMutablePointer<Int8>(mutating: (auth_signatures as NSString).utf8String)
        var serversPointer: UnsafeMutablePointer<Int8>?
        if selected_servers != nil {
            serversPointer = UnsafeMutablePointer<Int8>(mutating: (selected_servers! as NSString).utf8String)
        }
        
        var newFactorPubPointer: OpaquePointer?
        if new_factor_pub != nil {
            newFactorPubPointer = new_factor_pub!.pointer
        }
        
        var new_tss_index_mutable: Int32 = new_tss_index ?? 2
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            withUnsafeMutablePointer(to: &new_tss_index_mutable,
                                     { newTssIndexPointer in
                tss_options(inputSharePointer, tss_input_index, factor_pub.pointer, authSignaturesPointer, serversPointer, newTssIndexPointer, newFactorPubPointer, error)
            })
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in TssOptions, init")
            }
        pointer = result
    }

    deinit {
        tss_options_free(pointer)
    }
}
