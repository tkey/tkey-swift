import Foundation
#if canImport(lib)
import lib
#endif

public final class NodeDetails {
    private(set) var pointer: OpaquePointer?

    public init(serverEndpoints: String, serverPublicKeys: String, serverThreshold: Int32) throws {
        var errorCode: Int32 = -1
        let endpointPointer = UnsafeMutablePointer<Int8>(mutating: (serverEndpoints as NSString).utf8String)
        let pubKeyPointer = UnsafeMutablePointer<Int8>(mutating: (serverPublicKeys as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            node_details(endpointPointer, pubKeyPointer, serverThreshold, error)
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
