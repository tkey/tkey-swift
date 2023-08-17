import Foundation
#if canImport(lib)
import lib
#endif

// rss server opts
public final class ServerOpts {
    private(set) var pointer: OpaquePointer?

    public init(server_endpoints: String, server_pub_keys: String, server_threshold: Int32, selected_servers: String? = nil, auth_signatures: [String]) throws {
        let auth_signatures_json = try JSONSerialization.data(withJSONObject: auth_signatures)
        guard let auth_signatures_str = String(data: auth_signatures_json, encoding: .utf8) else {
            throw RuntimeError("auth signatures error")
        };
        
        var errorCode: Int32 = -1
        let authSignaturesPointer = UnsafeMutablePointer<Int8>(mutating: (auth_signatures_str as NSString).utf8String)
        var serversPointer: UnsafeMutablePointer<Int8>?
        if selected_servers != nil {
            serversPointer = UnsafeMutablePointer<Int8>(mutating: (selected_servers! as NSString).utf8String)
        }
        
        let endpointPointer = UnsafeMutablePointer<Int8>(mutating: (server_endpoints as NSString).utf8String)
        let pubKeyPointer = UnsafeMutablePointer<Int8>(mutating: (server_pub_keys as NSString).utf8String)
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            server_opts(endpointPointer, pubKeyPointer, server_threshold, serversPointer, authSignaturesPointer, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in serverOpts, init")
        }
        pointer = result
    }

    deinit {
        server_opts_free(pointer)
    }
}
