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
    ///
    /// - Returns: `ServiceProvider`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters were used.
    public init(enable_logging: Bool, postbox_key: String, useTss: Bool = false) throws {
        var errorCode: Int32 = -1
        let postboxPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: postbox_key).utf8String)
        let curve = UnsafeMutablePointer<Int8>(mutating: NSString(string: curveN).utf8String)
        let result: OpaquePointer? = withUnsafeMutablePointer(to: &errorCode, { error in
            service_provider(enable_logging, postboxPointer,
                curve,
                useTss,
                nil,
                nil,
                nil,
                nil,
                nil,
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
