import Foundation
#if canImport(lib)
    import lib
#endif

public final class ServiceProvider {
    private(set) var pointer: OpaquePointer?
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

    /// Instantiate a `ServiceProvider` object.
    ///
    /// - Parameters:
    ///   - enable_logging: Determines if logging is enabled or not.
    ///   - postbox_key: The private key to be used for the ServiceProvider.
    ///   - useTss: Whether tss is used or not.
    ///   - verifierName: Name of verifier, used with tss
    ///   - verifierId: Id of verifier, used with tss
    ///   - tssNodeDetails: tss service information, used with tss
    ///   - rssNodeDetails: rss service information, used with tss
    ///   - sssNodeDetails: sss service information, used with tss
    ///
    /// - Returns: `ServiceProvider`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters were used.
    public init(enable_logging: Bool, postbox_key: String, useTss: Bool = false, verifierName: String?, verifierId: String?, tssNodeDetails: NodeDetails?, rssNodeDetails: NodeDetails?, sssNodeDetails: NodeDetails?) throws {
        var errorCode: Int32 = -1
        let postboxPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: postbox_key).utf8String)
        let curve = UnsafeMutablePointer<Int8>(mutating: NSString(string: curveN).utf8String)
        var verifierNamePointer: UnsafeMutablePointer<Int8>?
        if verifierName != nil {
            verifierNamePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: verifierName!).utf8String)
        }
        var verifierIdPointer: UnsafeMutablePointer<Int8>?
        if verifierId != nil {
            verifierNamePointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: verifierId!).utf8String)
        }
        
        var tssPointer: OpaquePointer?
        if tssNodeDetails != nil {
            tssPointer = tssNodeDetails!.pointer
        }
        var rssPointer: OpaquePointer?
        if rssNodeDetails != nil {
            rssPointer = rssNodeDetails!.pointer
        }
        var sssPointer: OpaquePointer?
        if sssNodeDetails != nil {
            sssPointer = sssNodeDetails!.pointer
        }
        
        let result: OpaquePointer? = withUnsafeMutablePointer(to: &errorCode, { error in
            service_provider(enable_logging, postboxPointer,
                curve,
                useTss,
                verifierNamePointer,
                verifierIdPointer,
                tssPointer,
                rssPointer,
                sssPointer,
                error)
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
