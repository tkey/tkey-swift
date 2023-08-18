import Foundation
import TorusUtils
#if canImport(lib)
    import lib
#endif
import FetchNodeDetails
import CommonSources

public final class ServiceProvider {
    private(set) var pointer: OpaquePointer?
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

    /// Instantiate a `ServiceProvider` object.
    ///
    /// - Parameters:
    ///   - enableLogging: Determines if logging is enabled or not.
    ///   - postboxKey: The private key to be used for the ServiceProvider.
    ///   - useTss: Whether tss is used or not.
    ///   - torus-utils : Torus-utils
    ///
    /// - Returns: `ServiceProvider`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters were used.
    public init(enableLogging: Bool, postboxKey: String, useTss: Bool = false, verifier: String?=nil, verifierId: String?=nil, nodeDetails: AllNodeDetailsModel? = nil ) throws {
        var errorCode: Int32 = -1
        let postboxPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: postboxKey).utf8String)
        let curve = UnsafeMutablePointer<Int8>(mutating: NSString(string: curveN).utf8String)

        var verifierPtr: UnsafeMutablePointer<Int8>?
        var verifierIdPtr: UnsafeMutablePointer<Int8>?

        if let verifier = verifier,
            let verifierId = verifierId {
            verifierPtr = UnsafeMutablePointer<Int8>(mutating: NSString(string: verifier).utf8String)
            verifierIdPtr = UnsafeMutablePointer<Int8>(mutating: NSString(string: verifierId).utf8String)
        }

        var sss: NodeDetails?
        var rss: NodeDetails?
        var tss: NodeDetails?
        if let nodeDetails = nodeDetails {
            let sssEndpoints = try JSONSerialization.data(withJSONObject: nodeDetails.getTorusNodeSSSEndpoints())
            let rssEndpoints = try JSONSerialization.data(withJSONObject: nodeDetails.getTorusNodeRSSEndpoints())
            let tssEndpoints = try JSONSerialization.data(withJSONObject: nodeDetails.getTorusNodeTSSEndpoints())

            let pub = nodeDetails.torusNodePub
            let pubkey = try JSONEncoder().encode(pub)

            sss = try NodeDetails(serverEndpoints: String(data: sssEndpoints, encoding: .utf8)!, serverPublicKeys: String(data: pubkey, encoding: .utf8)!, serverThreshold: 3)
            rss = try NodeDetails(serverEndpoints: String(data: rssEndpoints, encoding: .utf8)!, serverPublicKeys: String(data: pubkey, encoding: .utf8)!, serverThreshold: 3)
            tss = try NodeDetails(serverEndpoints: String(data: tssEndpoints, encoding: .utf8)!, serverPublicKeys: String(data: pubkey, encoding: .utf8)!, serverThreshold: 3)
        }

        let result: OpaquePointer? = withUnsafeMutablePointer(to: &errorCode, { error in
            service_provider(enableLogging, postboxPointer,
                curve,
                useTss,
                verifierPtr,
                verifierIdPtr,
                 tss?.pointer,
                 rss?.pointer,
                 sss?.pointer,
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
