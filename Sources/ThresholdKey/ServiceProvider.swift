import Foundation
import TorusUtils
#if canImport(lib)
    import lib
#endif
import FetchNodeDetails
import CommonSources

public struct GetTSSPubKeyResult : Codable {
    public struct Point: Codable {
        var x: String;
        var y: String
    }
    public var publicKey : Point
    public var nodeIndexes : [Int]
}


public final class ServiceProvider {
    private(set) var pointer: OpaquePointer?
    internal let curveN = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
    
    internal var verifier : String?
    internal var verifierId : String?
    internal var nodeDetails : AllNodeDetailsModel?
    internal var torusUtils : TorusUtils?
    
    public var useTss : Bool
    

    /// Instantiate a `ServiceProvider` object.
    ///
    /// - Parameters:
    ///   - enable_logging: Determines if logging is enabled or not.
    ///   - postbox_key: The private key to be used for the ServiceProvider.
    ///   - useTss: Whether tss is used or not.
    ///   - torus-utils : Torus-utils
    ///
    /// - Returns: `ServiceProvider`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters were used.
    public init(enable_logging: Bool, postbox_key: String, useTss: Bool = false, verifier: String?=nil, verifierId: String?=nil, nodeDetails: AllNodeDetailsModel? = nil, torusUtils: TorusUtils? = nil ) throws {
        var errorCode: Int32 = -1
        let postboxPointer = UnsafeMutablePointer<Int8>(mutating: NSString(string: postbox_key).utf8String)
        let curve = UnsafeMutablePointer<Int8>(mutating: NSString(string: curveN).utf8String)
        
        var verifierPtr : UnsafeMutablePointer<Int8>? = nil
        var verifierIdPtr : UnsafeMutablePointer<Int8>? = nil
        
        if let verifier = verifier,
            let verifierId = verifierId {
            verifierPtr = UnsafeMutablePointer<Int8>(mutating: NSString(string: verifier).utf8String)
            verifierIdPtr = UnsafeMutablePointer<Int8>(mutating: NSString(string: verifierId).utf8String)
        }
        
        var sssPtr :OpaquePointer? = nil
        var rssPtr :OpaquePointer? = nil
        var tssPtr :OpaquePointer? = nil
        
        if let nodeDetails = nodeDetails
        {
            let sssEndpoints = try JSONSerialization.data(withJSONObject: nodeDetails.getTorusNodeSSSEndpoints())
            let rssEndpoints = try JSONSerialization.data(withJSONObject: nodeDetails.getTorusNodeRSSEndpoints())
            let tssEndpoints = try JSONSerialization.data(withJSONObject: nodeDetails.getTorusNodeTSSEndpoints())
            
            let pub = nodeDetails.torusNodePub
//            let pubkey = try JSONSerialization.data(withJSONObject: pub)
            let pubkey = try JSONEncoder().encode(pub)
            
            print( String(data: pubkey, encoding: .utf8))
            
                        
            let sss = try NodeDetails(server_endpoints: String(data: sssEndpoints, encoding: .utf8)!, server_public_keys: String(data: pubkey, encoding: .utf8)!, serverThreshold: 3)
            let rss = try NodeDetails(server_endpoints: String(data: rssEndpoints, encoding: .utf8)!, server_public_keys: String(data: pubkey, encoding: .utf8)!, serverThreshold: 3)
            let tss = try NodeDetails(server_endpoints: String(data: tssEndpoints, encoding: .utf8)!, server_public_keys: String(data: pubkey, encoding: .utf8)!, serverThreshold: 3)
            
            sssPtr = sss.pointer
            rssPtr = rss.pointer
            tssPtr = tss.pointer
            
        }
        
        
        let result: OpaquePointer? = withUnsafeMutablePointer(to: &errorCode, { error in
            service_provider(enable_logging, postboxPointer,
                curve,
                useTss,
                verifierPtr,
                verifierIdPtr,
                 rssPtr,
                 sssPtr,
                 tssPtr,
                error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in ServiceProvider")
            }
        
        self.nodeDetails = nodeDetails
        self.torusUtils = torusUtils
        self.verifier = verifier
        self.verifierId = verifierId
        self.useTss = useTss
        pointer = result!
    }
    
    func getTssPubAddress (tssTag : String, nonce: String) async throws -> GetTSSPubKeyResult  {
        guard let verifier = self.verifier, let verifierId = verifierId , let nodeDetails = self.nodeDetails else {
            throw RuntimeError("missing verifier, verifierId")
        }
        let extendedVerifierId = "\(verifierId)\u{0015}\(tssTag)\u{0016}\(nonce)"
        
        let result = try await self.torusUtils?.getPublicAddressExtended(endpoints: nodeDetails.torusNodeEndpoints, verifier: verifier, verifierId: verifierId, extendedVerifierId: extendedVerifierId)
        print (result)
        guard let x = result?.x , let y = result?.y, let nodeIndexes = result?.nodeIndexes else {
            throw RuntimeError("conversion error")
        }
        let pubKey = GetTSSPubKeyResult.Point(x: x, y: y)
        
        return GetTSSPubKeyResult(publicKey: pubKey, nodeIndexes: nodeIndexes)
    }
    
    deinit {
        service_provider_free(pointer)
    }
}
