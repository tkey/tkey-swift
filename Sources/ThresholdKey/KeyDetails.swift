import Foundation
#if canImport(lib)
    import lib
#endif

public final class KeyDetails {
    public let pubKey: KeyPoint
    public let requiredShares: Int32
    public let threshold: UInt32
    public let totalShares: UInt32
    public let shareDescriptions: String

    /// Instantiate a `KeyDetails` object using the underlying pointer.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to the underlying foreign function interface object.
    ///
    /// - Returns: `KeyDetails`
    ///
    /// - Throws: `RuntimeError`, indicates underlying pointer is invalid.
    public init(pointer: OpaquePointer) throws {
        var errorCode: Int32 = -1
        let point = withUnsafeMutablePointer(to: &errorCode, { error in
           key_details_get_pub_key_point(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Point")
            }
        pubKey = KeyPoint.init(pointer: point!)

        let theshold = withUnsafeMutablePointer(to: &errorCode, { error in
           key_details_get_threshold(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Threshold")
            }
        self.threshold = theshold

        let requiredShares = withUnsafeMutablePointer(to: &errorCode, { error in
           key_details_get_required_shares(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Required Shares")
            }
        self.requiredShares = requiredShares

        let totalShares = withUnsafeMutablePointer(to: &errorCode, { error in
           key_details_get_total_shares(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Total Shares")
            }
        self.totalShares = totalShares

        let shareDescriptions = withUnsafeMutablePointer(to: &errorCode, { error in
           key_details_get_share_descriptions(pointer, error)
               })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyDetails, field Share Descriptions")
            }
        self.shareDescriptions = String.init(cString: shareDescriptions!)
        string_free(shareDescriptions)
        key_details_free(pointer)
    }
}
