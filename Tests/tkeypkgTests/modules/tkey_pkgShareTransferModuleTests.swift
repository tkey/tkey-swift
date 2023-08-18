import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgShareTransferModuleTests: XCTestCase {
    private var thresholdKey: ThresholdKey!
    private var threshold_key2: ThresholdKey!
    private var k1: KeyReconstructionDetails!

    override func setUp() async throws {
        let postboxKey = try! PrivateKey.generate()
        let storageLayer = try! StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2)
        let serviceProvider = try! ServiceProvider(enableLogging: true, postboxKey: postboxKey.hex)
        let threshold = try! ThresholdKey(
            storageLayer: storageLayer,
            serviceProvider: serviceProvider,
            enableLogging: true,
            manualSync: false
        )

        _ = try! await threshold.initialize()
        k1 = try! await threshold.reconstruct()
        thresholdKey = threshold
        let threshold2 = try! ThresholdKey(storageLayer: storageLayer, serviceProvider: serviceProvider, enableLogging: false, manualSync: false)
        _ = try! await threshold2.initialize()
        threshold_key2 = threshold2

    }

    override func tearDown() {
        thresholdKey = nil
        threshold_key2 = nil
        k1 = nil
    }

    func test_share_transfer_store_and_encryption_key_retrieval() async {
        XCTAssertEqual("", try! ShareTransferModule.get_current_encryption_key(thresholdKey: threshold_key2))
        _ = try! await ShareTransferModule.request_new_share(thresholdKey: threshold_key2, userAgent: "", availableShareIndexes: "[]")
        XCTAssertNotEqual("", try! ShareTransferModule.get_current_encryption_key(thresholdKey: threshold_key2))
        let store = try! await ShareTransferModule.get_store(thresholdKey: thresholdKey)
        let lookup = try! await ShareTransferModule.look_for_request(thresholdKey: thresholdKey)
        let enc_pub_key = lookup[0]
        _ = try! await ShareTransferModule.delete_store(thresholdKey: thresholdKey, encPubKeyX: enc_pub_key)
        _ = try! await ShareTransferModule.set_store(thresholdKey: thresholdKey, store: store)
        _ = try! await ShareTransferModule.get_store(thresholdKey: thresholdKey)
        try! ShareTransferModule.cleanup_request(thresholdKey: threshold_key2)
        XCTAssertEqual("", try! ShareTransferModule.get_current_encryption_key(thresholdKey: threshold_key2))
    }

    func test_approve_with_index() async {
        let request_enc = try! await ShareTransferModule.request_new_share(thresholdKey: threshold_key2, userAgent: "agent", availableShareIndexes: "[]")
        let lookup = try! await ShareTransferModule.look_for_request(thresholdKey: thresholdKey)
        let encPubKey = lookup[0]
        let newShare = try! await thresholdKey.generate_new_share()
        try! await ShareTransferModule.approve_request_with_share_index(thresholdKey: thresholdKey, encPubKeyX: encPubKey, shareIndex: newShare.hex)
        _ = try! await ShareTransferModule.add_custom_info_to_request(thresholdKey: threshold_key2, encPubKeyX: request_enc, customInfo: "test info")
        _ = try! await ShareTransferModule.request_status_check(thresholdKey: threshold_key2, encPubKeyX: request_enc, deleteRequestOnCompletion: true)

        let k2 = try! await threshold_key2.reconstruct()

        XCTAssertEqual(k1.key, k2.key)
    }

    func test_approve() async {
        let request_enc = try! await ShareTransferModule.request_new_share(thresholdKey: threshold_key2, userAgent: "agent", availableShareIndexes: "[]")
        let lookup = try! await ShareTransferModule.look_for_request(thresholdKey: thresholdKey)
        let enc_pub_key = lookup[0]
        var share_store: ShareStore?
        let new_share = try! await thresholdKey.generate_new_share()
        for (index, share) in new_share.shareStore.shareMaps {
            if index == new_share.hex {
                share_store = share
            }
        }
        try! await ShareTransferModule.approve_request(thresholdKey: thresholdKey, encPubKeyX: enc_pub_key, shareStore: share_store!)
        _ = try! await ShareTransferModule.request_status_check(thresholdKey: threshold_key2, encPubKeyX: request_enc, deleteRequestOnCompletion: true)
        let k2 = try! await threshold_key2.reconstruct()

        XCTAssertEqual(k1.key, k2.key)
    }
}
