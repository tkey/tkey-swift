import Foundation
#if canImport(lib)
import lib
#endif

public final class TssOptions {
    private(set) var pointer: OpaquePointer?

    public init(inputTssShare: String, tssInputIndex: Int32, authSignatures: [String], factorPub: KeyPoint,
                selectedServers: String? = nil, newTssIndex: Int32? = nil, newFactorPub: KeyPoint? = nil) throws {
        let authSignaturesJson = try JSONSerialization.data(withJSONObject: authSignatures)
        guard let authSignaturesStr = String(data: authSignaturesJson, encoding: .utf8) else {
            throw RuntimeError("auth signatures error")
        }

        var errorCode: Int32 = -1
        let inputSharePointer = UnsafeMutablePointer<Int8>(mutating: (inputTssShare as NSString).utf8String)
        let authSignaturesPointer = UnsafeMutablePointer<Int8>(mutating: (authSignaturesStr as NSString).utf8String)
        var serversPointer: UnsafeMutablePointer<Int8>?
        if selectedServers != nil {
            serversPointer = UnsafeMutablePointer<Int8>(mutating: (selectedServers! as NSString).utf8String)
        }

        var newFactorPubPointer: OpaquePointer?
        if newFactorPub != nil {
            newFactorPubPointer = newFactorPub!.pointer
        }

        var newTssIndexMutable: Int32 = newTssIndex ?? 2
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            withUnsafeMutablePointer(to: &newTssIndexMutable, { newTssIndexPointer in
                tss_options(inputSharePointer, tssInputIndex, factorPub.pointer, authSignaturesPointer, serversPointer, newTssIndexPointer, newFactorPubPointer, error)
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
