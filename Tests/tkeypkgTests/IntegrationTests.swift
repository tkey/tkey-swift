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

        let postboxKey = try! PrivateKey.generate()
        let storageLayer = try! StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2)
        let serviceProvider = try! ServiceProvider(enableLogging: true, postboxKey: postboxKey.hex, useTss: true, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, nodeDetails: nodeDetail)
        let rssComm = try! RssComm()
        let threshold = try! ThresholdKey(
            storageLayer: storageLayer,
            serviceProvider: serviceProvider,
            enableLogging: true,
            manualSync: false,
            rssComm: rssComm
        )

        _ = try! await threshold.initialize()
        _ = try! await threshold.reconstruct()
        let shareIndex = try! await threshold.generate_new_share()
        let share = try threshold.output_share(shareIndex: shareIndex.hex)

        let tssTag = "testing"
        let factorKey = try PrivateKey.generate()
        let factorPub = try factorKey.toPublic()
        try TssModule.backup_share_with_factor_key(thresholdKey: threshold, shareIndex: shareIndex.hex, factorKey: factorKey.hex)

        try await TssModule.create_tagged_tss_share(thresholdKey: threshold, tssTag: tssTag, deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2, nodeDetails: nodeDetail, torusUtils: torusUtils)

        let (tss_index, tss_share) = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tssTag, factorKey: factorKey.hex)

        try await threshold.sync_local_metadata_transistions()

        let newFactorKey = try PrivateKey.generate()
        let newFactorPub = try newFactorKey.toPublic()
        // 2/2 -> 2/3 tss
        try await TssModule.generate_tss_share(thresholdKey: threshold, tssTag: tssTag, inputTssShare: tss_share, tssInputIndex: Int32(tss_index)!, authSignatures: signatures, newFactorPub: newFactorPub, newTssIndex: 3, nodeDetails: nodeDetail, torusUtils: torusUtils)
        let (tss_index3, tss_share3) = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tssTag, factorKey: newFactorKey.hex)

        let (_, tss_share_updated) = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tssTag, factorKey: factorKey.hex)

        // after refresh (generate new share), existing tss_share is not valid anymore, new tss share1 is return
        XCTAssertNotEqual(tss_share, tss_share_updated)
        XCTAssertNotEqual(tss_share_updated, tss_share3)
        XCTAssertNotEqual(tss_index, tss_index3)
        // Initialize on Instance 2
        let threshold2 = try! ThresholdKey(
            storageLayer: storageLayer,
            serviceProvider: serviceProvider,
            enableLogging: true,
            manualSync: false
        )
        _ = try! await threshold2.initialize()

        try await threshold2.input_factor_key(factorKey: factorKey.hex)
        _ = try! await threshold2.reconstruct()

        // Try get testing tss tag share on Instance 2
        let (tss_index2, tss_share2) = try await TssModule.get_tss_share(thresholdKey: threshold2, tssTag: tssTag, factorKey: factorKey.hex)

        XCTAssertNotEqual(tss_share, tss_share2)
        XCTAssertEqual(tss_share_updated, tss_share2)
        XCTAssertEqual(tss_index, tss_index2)

        let (tss_index2_3, tss_share2_3) = try await TssModule.get_tss_share(thresholdKey: threshold2, tssTag: tssTag, factorKey: newFactorKey.hex)

        XCTAssertEqual(tss_share3, tss_share2_3)
        XCTAssertEqual(tss_index3, tss_index2_3)

        // 2/3 -> 2/2 tss
        try await TssModule.delete_tss_share(thresholdKey: threshold, tssTag: tssTag, inputTssShare: tss_share3, tssInputIndex: Int32(tss_index3)!, authSignatures: signatures, deleteFactorPub: newFactorPub, nodeDetails: nodeDetail, torusUtils: torusUtils)
        // XCTAssertThrowsError( try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tssTag, factorKey: newFactorKey.hex) )

        let (tss_index_updated2, tss_share_updated2) = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tssTag, factorKey: factorKey.hex)
        XCTAssertEqual(tss_index_updated2, tss_index)

        XCTAssertNotEqual(tss_share, tss_share_updated2)
        XCTAssertNotEqual(tss_share_updated, tss_share_updated2)

        // 2/2 -> 2/3 tss
        try await TssModule.add_factor_pub(thresholdKey: threshold, tssTag: tssTag, factorKey: factorKey.hex, authSignatures: signatures, newFactorPub: newFactorPub, newTssIndex: 3, nodeDetails: nodeDetail, torusUtils: torusUtils)

        // 2/3 -> 2/2 tss
        try await TssModule.delete_factor_pub(thresholdKey: threshold, tssTag: tssTag, factorKey: factorKey.hex, authSignatures: signatures, deleteFactorPub: newFactorPub, nodeDetails: nodeDetail, torusUtils: torusUtils)
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

        let postboxKey = try! PrivateKey.generate()
        let storageLayer = try! StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2)
        let serviceProvider = try! ServiceProvider(enableLogging: true, postboxKey: postboxKey.hex, useTss: true, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, nodeDetails: nodeDetail)
        let rssComm = try RssComm()
        threshold = try! ThresholdKey(
            storageLayer: storageLayer,
            serviceProvider: serviceProvider,
            enableLogging: true,
            manualSync: true,
            rssComm: rssComm
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

            try await TssModule.set_tss_tag(thresholdKey: threshold, tssTag: tag)
            try await TssModule.create_tagged_tss_share(thresholdKey: threshold, tssTag: tag, deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2, nodeDetails: nodeDetail, torusUtils: torusUtils)

            let (tssIndex, tssShare) = try! await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tag, factorKey: factorKey.hex)
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
            try await TssModule.add_factor_pub(thresholdKey: threshold, tssTag: tag, factorKey: factorKeys[index].hex, authSignatures: signatures, newFactorPub: newFactorPub, newTssIndex: 3, nodeDetails: nodeDetail, torusUtils: torusUtils)

            try await threshold.sync_local_metadata_transistions()

            let (tssIndex, tssShare) = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tag, factorKey: factorKeys[index].hex)
            XCTAssertEqual(tssIndex, tssIndexes[index])
            XCTAssertNotEqual(tssShare, tssShares[index])

            let (tssIndex1, tssShare1) = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tag, factorKey: newFactorKey.hex)
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
            try await TssModule.copy_factor_pub(thresholdKey: threshold, tssTag: tag, factorKey: newFactorKeys[index].hex, newFactorPub: newFactorPub2, tssIndex: 3)

            let (tssIndex, tssShare) = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tag, factorKey: factorKeys[index].hex)
            XCTAssertEqual(tssIndex, tssIndexes[index])
            XCTAssertNotEqual(tssShare, tssShares[index])

            let (tssIndex1, tssShare1) = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tag, factorKey: newFactorKeys[index].hex)
            XCTAssertNotEqual(tssIndex1, tssIndexes[index])
            XCTAssertNotEqual(tssShare1, tssShares[index])

            let (tssIndex2, tssShare2) = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tag, factorKey: newFactorKeys2[index].hex)
            XCTAssertEqual(tssIndex1, tssIndex2)
            XCTAssertEqual(tssShare1, tssShare2)
        }
        try await threshold.sync_local_metadata_transistions()

        // Initialize on Instance 2
        threshold2 = try! ThresholdKey(
            storageLayer: storageLayer,
            serviceProvider: serviceProvider,
            enableLogging: true,
            manualSync: false
        )
        _ = try! await threshold2.initialize()
        try! await threshold2.input_share(share: share, shareType: nil)
        _ = try! await threshold2.reconstruct()

        var tssModsInstance2: [(ThresholdKey, String)] = []
        // check on new instances (instance 2 )
        for (index, tag) in testTags.enumerated() {
            tssModsInstance2.append((threshold, tag))
            _ = try await TssModule.get_tss_share(thresholdKey: threshold, tssTag: tag, factorKey: factorKeys[index].hex)
        }

        try await threshold.sync_local_metadata_transistions()

        // delete factor key
        for (index, (threshold, tag)) in tssModsInstance2.enumerated() {
            let newFactorKey2 = try PrivateKey.generate()
            let newFactorPub2 = try newFactorKey2.toPublic()

            newFactorKeys2.append(newFactorKey2)
            newFactorPubs2.append(newFactorPub2)
            try await TssModule.delete_factor_pub(thresholdKey: threshold, tssTag: tag, factorKey: newFactorKeys[index].hex, authSignatures: signatures, deleteFactorPub: newFactorPubs[index], nodeDetails: nodeDetail, torusUtils: torusUtils)
        }
        try await threshold.sync_local_metadata_transistions()
        print(try threshold.get_all_tss_tags())
    }
}
