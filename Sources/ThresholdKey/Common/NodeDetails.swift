import Foundation
#if canImport(lib)
import lib
#endif

public final class NodeDetails {
    private(set) var pointer: OpaquePointer?
    
    public init(pointer: OpaquePointer?) {
        self.pointer = pointer
    }
    
    public init(server_endpoints: String, server_public_keys: String, serverThreshold: Int32) throws {
        var errorCode: Int32 = -1
        let endpointPointer = UnsafeMutablePointer<Int8>(mutating: (server_endpoints as NSString).utf8String)
        let pubKeyPointer = UnsafeMutablePointer<Int8>(mutating: (server_public_keys as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            node_details(endpointPointer,pubKeyPointer, serverThreshold, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in NodeDetails, init")
            }
        pointer = result
    }
    
    deinit {
        node_details_free(pointer)
    }
}
