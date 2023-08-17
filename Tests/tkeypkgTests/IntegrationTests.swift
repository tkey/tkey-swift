import CommonSources
import FetchNodeDetails
import Foundation
import TorusUtils
import XCTest
@testable import tkey_pkg

final class integrationTests: XCTestCase {
    func test_TssModule() async throws {
        let TORUS_TEST_EMAIL = "saasa2123@tr.us"
        // let TORUS_IMPORT_EMAIL = "importeduser2@tor.us";

        // let TORUS_EXTENDED_VERIFIER_EMAIL = "testextenderverifierid@example.com";

        let TORUS_TEST_VERIFIER = "torus-test-health"

        let nodeManager = NodeDetailManager(network: .sapphire(.SAPPHIRE_DEVNET))
        let nodeDetail = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL)
        let torusUtils = TorusUtils(serverTimeOffset: 1000, network: .sapphire(.SAPPHIRE_DEVNET))

        let idToken = try generateIdToken(email: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        let retrievedShare = try await torusUtils.retrieveShares(endpoints: nodeDetail.torusNodeEndpoints, torusNodePubs: nodeDetail.torusNodePub, indexes: nodeDetail.torusIndexes, verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: idToken)
        let signature = retrievedShare.sessionData?.sessionTokenData
        let signatures = signature!.compactMap { item in
            item?.signature
        }

        let postbox_key = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox_key.hex, useTss: true, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, nodeDetails: nodeDetail)
        let rss_comm = try! RssComm()
        let threshold = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false,
            rss_comm: rss_comm
        )

        _ = try! await threshold.initialize()
        _ = try! await threshold.reconstruct()
        let shareIndex = try! await threshold.generate_new_share()
        let share = try threshold.output_share(shareIndex: shareIndex.hex)

        let tssTag = "testing"
        let factorKey = try PrivateKey.generate()
        let factorPub = try factorKey.toPublic()
        try TssModule.backup_share_with_factor_key(threshold_key: threshold, shareIndex: shareIndex.hex, factorKey: factorKey.hex)
        
        try await TssModule.create_tagged_tss_share(threshold_key: threshold, tss_tag: tssTag, deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2, nodeDetails: nodeDetail, torusUtils: torusUtils)

        let (tss_index, tss_share) = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tssTag, factorKey: factorKey.hex)

        try await threshold.sync_local_metadata_transistions()

        let newFactorKey = try PrivateKey.generate()
        let newFactorPub = try newFactorKey.toPublic()
        // 2/2 -> 2/3 tss
        try await TssModule.generate_tss_share(threshold_key: threshold, tss_tag: tssTag, input_tss_share: tss_share, tss_input_index: Int32(tss_index)!, auth_signatures: signatures, new_factor_pub: newFactorPub, new_tss_index: 3, nodeDetails: nodeDetail, torusUtils: torusUtils)
        let (tss_index3, tss_share3) = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tssTag, factorKey: newFactorKey.hex)

        let (_, tss_share_updated) = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tssTag, factorKey: factorKey.hex)

        // after refresh (generate new share), existing tss_share is not valid anymore, new tss share1 is return
        XCTAssertNotEqual(tss_share, tss_share_updated)
        XCTAssertNotEqual(tss_share_updated, tss_share3)
        XCTAssertNotEqual(tss_index, tss_index3)
        // Initialize on Instance 2
        let threshold2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
        )
        _ = try! await threshold2.initialize()
        
        try await threshold2.input_factor_key(factorKey: factorKey.hex)
        _ = try! await threshold2.reconstruct()

        // Try get testing tss tag share on Instance 2
        let (tss_index2, tss_share2) = try await TssModule.get_tss_share(threshold_key: threshold2, tss_tag: tssTag, factorKey: factorKey.hex)

        XCTAssertNotEqual(tss_share, tss_share2)
        XCTAssertEqual(tss_share_updated, tss_share2)
        XCTAssertEqual(tss_index, tss_index2)

        let (tss_index2_3, tss_share2_3) = try await TssModule.get_tss_share(threshold_key: threshold2, tss_tag: tssTag, factorKey: newFactorKey.hex)

        XCTAssertEqual(tss_share3, tss_share2_3)
        XCTAssertEqual(tss_index3, tss_index2_3)

        // 2/3 -> 2/2 tss
        try await TssModule.delete_tss_share(threshold_key: threshold, tss_tag: tssTag, input_tss_share: tss_share3, tss_input_index: Int32(tss_index3)!, auth_signatures: signatures, delete_factor_pub: newFactorPub, nodeDetails: nodeDetail, torusUtils: torusUtils)
        // XCTAssertThrowsError( try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tssTag, factorKey: newFactorKey.hex) )

        let (tss_index_updated2, tss_share_updated2) = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tssTag, factorKey: factorKey.hex)
        XCTAssertEqual(tss_index_updated2, tss_index)

        XCTAssertNotEqual(tss_share, tss_share_updated2)
        XCTAssertNotEqual(tss_share_updated, tss_share_updated2)

        // 2/2 -> 2/3 tss
        try await TssModule.add_factor_pub(threshold_key: threshold, tss_tag: tssTag, factor_key: factorKey.hex, auth_signatures: signatures, new_factor_pub: newFactorPub, new_tss_index: 3, nodeDetails: nodeDetail, torusUtils: torusUtils)

        // 2/3 -> 2/2 tss
        try await TssModule.delete_factor_pub(threshold_key: threshold, tss_tag: tssTag, factor_key: factorKey.hex, auth_signatures: signatures, delete_factor_pub: newFactorPub, nodeDetails: nodeDetail, torusUtils: torusUtils)
    }

    func test_TssModule_multi_tag() async throws {
        let TORUS_TEST_EMAIL = "saasa34@tr.us"
        // let TORUS_IMPORT_EMAIL = "importeduser2@tor.us";

        // let TORUS_EXTENDED_VERIFIER_EMAIL = "testextenderverifierid@example.com";

        let TORUS_TEST_VERIFIER = "torus-test-health"

        var threshold: ThresholdKey!
        var threshold2: ThresholdKey!

        let nodeManager = NodeDetailManager(network: .sapphire(.SAPPHIRE_DEVNET))
        let nodeDetail = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL)
        let torusUtils = TorusUtils(serverTimeOffset: 1000, network: .sapphire(.SAPPHIRE_DEVNET))

        let idToken = try generateIdToken(email: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        let retrievedShare = try await torusUtils.retrieveShares(endpoints: nodeDetail.torusNodeSSSEndpoints, torusNodePubs: nodeDetail.torusNodePub, indexes: nodeDetail.torusIndexes, verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: idToken)
        print(retrievedShare)
        let signature = retrievedShare.sessionData!.sessionTokenData
        let signatures = signature.compactMap { item in
            item?.signature
        }

        let postbox_key = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox_key.hex, useTss: true, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, nodeDetails: nodeDetail)
        let rss_comm = try RssComm()
        threshold = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: true,
            rss_comm: rss_comm
        )

        _ = try! await threshold.initialize()
        _ = try! await threshold.reconstruct()
        let shareIndex = try! await threshold.generate_new_share()
        let share = try threshold.output_share(shareIndex: shareIndex.hex)
        print(share)

        let testTags = ["tag1", "tag2", "tag3", "tag4", "tag5"]

        var tssMods: [(ThresholdKey, String)] = []

        var factorKeys: [PrivateKey] = []
        var factorPubs: [String] = []

        var tssIndexes: [String] = []
        var tssShares: [String] = []

        print(try threshold.get_all_tss_tags())
        for tag in testTags {
            // create tag tss module

            tssMods.append((threshold, tag))

            let factorKey = try PrivateKey.generate()
            let factorPub = try factorKey.toPublic()
            factorKeys.append(factorKey)
            factorPubs.append(factorPub)

            try await TssModule.set_tss_tag(threshold_key: threshold, tss_tag: tag)
            try await TssModule.create_tagged_tss_share(threshold_key: threshold, tss_tag: tag, deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2, nodeDetails: nodeDetail, torusUtils: torusUtils)

            let (tssIndex, tssShare) = try! await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tag, factorKey: factorKey.hex)
            tssIndexes.append(tssIndex)
            tssShares.append(tssShare)
        }
        try await threshold.sync_local_metadata_transistions()

        var newFactorKeys: [PrivateKey] = []
        var newFactorPubs: [String] = []
        // add factor key
        for (index, (threshold, tag)) in tssMods.enumerated() {
            let newFactorKey = try PrivateKey.generate()
            let newFactorPub = try newFactorKey.toPublic()

            newFactorKeys.append(newFactorKey)
            newFactorPubs.append(newFactorPub)
            try await TssModule.add_factor_pub(threshold_key: threshold, tss_tag: tag, factor_key: factorKeys[index].hex, auth_signatures: signatures, new_factor_pub: newFactorPub, new_tss_index: 3, nodeDetails: nodeDetail, torusUtils: torusUtils)

            try await threshold.sync_local_metadata_transistions()

            let (tssIndex, tssShare) = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tag, factorKey: factorKeys[index].hex)
            XCTAssertEqual(tssIndex, tssIndexes[index])
            XCTAssertNotEqual(tssShare, tssShares[index])

            let (tssIndex1, tssShare1) = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tag, factorKey: newFactorKey.hex)
            XCTAssertNotEqual(tssIndex1, tssIndexes[index])
            XCTAssertNotEqual(tssShare1, tssShares[index])
        }
        try await threshold.sync_local_metadata_transistions()

        // copy factor key
        var newFactorKeys2: [PrivateKey] = []
        var newFactorPubs2: [String] = []

        for (index, (threshold, tag)) in tssMods.enumerated() {
            let newFactorKey2 = try PrivateKey.generate()
            let newFactorPub2 = try newFactorKey2.toPublic()

            newFactorKeys2.append(newFactorKey2)
            newFactorPubs2.append(newFactorPub2)
            try await TssModule.copy_factor_pub(threshold_key: threshold, tss_tag: tag, factorKey: newFactorKeys[index].hex, newFactorPub: newFactorPub2, tss_index: 3)

            let (tssIndex, tssShare) = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tag, factorKey: factorKeys[index].hex)
            XCTAssertEqual(tssIndex, tssIndexes[index])
            XCTAssertNotEqual(tssShare, tssShares[index])

            let (tssIndex1, tssShare1) = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tag, factorKey: newFactorKeys[index].hex)
            XCTAssertNotEqual(tssIndex1, tssIndexes[index])
            XCTAssertNotEqual(tssShare1, tssShares[index])

            let (tssIndex2, tssShare2) = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tag, factorKey: newFactorKeys2[index].hex)
            XCTAssertEqual(tssIndex1, tssIndex2)
            XCTAssertEqual(tssShare1, tssShare2)
        }
        try await threshold.sync_local_metadata_transistions()

        // Initialize on Instance 2
        threshold2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
        )
        _ = try! await threshold2.initialize()
        try! await threshold2.input_share(share: share, shareType: nil)
        _ = try! await threshold2.reconstruct()

        var tssModsInstance2: [(ThresholdKey, String)] = []
        // check on new instances (instance 2 )
        for (index, tag) in testTags.enumerated() {
            tssModsInstance2.append((threshold, tag))
            _ = try await TssModule.get_tss_share(threshold_key: threshold, tss_tag: tag, factorKey: factorKeys[index].hex)
        }

        try await threshold.sync_local_metadata_transistions()

        // delete factor key
        for (index, (threshold, tag)) in tssModsInstance2.enumerated() {
            let newFactorKey2 = try PrivateKey.generate()
            let newFactorPub2 = try newFactorKey2.toPublic()

            newFactorKeys2.append(newFactorKey2)
            newFactorPubs2.append(newFactorPub2)
            try await TssModule.delete_factor_pub(threshold_key: threshold, tss_tag: tag, factor_key: newFactorKeys[index].hex, auth_signatures: signatures, delete_factor_pub: newFactorPubs[index], nodeDetails: nodeDetail, torusUtils: torusUtils)
        }
        try await threshold.sync_local_metadata_transistions()
        print(try threshold.get_all_tss_tags())
    }
}
