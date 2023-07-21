//
//  File.swift
//  
//
//  Created by CW Lee on 18/07/2023.
//

import XCTest
import Foundation
@testable import tkey_pkg
import Foundation
import CommonSources
import FetchNodeDetails
import TorusUtils


final class integrationTests: XCTestCase {
    
    let TORUS_TEST_EMAIL = "saasa1@tr.us";
    let TORUS_IMPORT_EMAIL = "importeduser2@tor.us";
    
    let TORUS_EXTENDED_VERIFIER_EMAIL = "testextenderverifierid@example.com";
    
    let TORUS_TEST_VERIFIER = "torus-test-health";
    

    var threshold: ThresholdKey!;
    var threshold2: ThresholdKey!;
    
    func test_Integration() async throws {
        let nodeManager = NodeDetailManager(network: .sapphire(.SAPPHIRE_DEVNET))
        let nodeDetail = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL)
        let torusUtils = TorusUtils(serverTimeOffset: 1000, network: .sapphire(.SAPPHIRE_DEVNET), metadataHost: "https://sapphire-dev-2-1.authnetwork.dev/metadata" )
        
        let idToken = try generateIdToken(email: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        let retrievedShare = try await torusUtils.retrieveShares(endpoints: nodeDetail.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: idToken)
        print (retrievedShare)
        let signature = retrievedShare.sessionTokenData
        let signatures = try signature.map{ item in
            guard let sig = item?.signature else {
                throw RuntimeError("fail to get signature")
            }
            return sig
        }
        
        let postbox_key = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox_key.hex, useTss: true, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, nodeDetails: nodeDetail, torusUtils: torusUtils)
        let rss_comm = try RssComm()
        threshold = try! ThresholdKey(
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
        print(share)
        
        
        try await threshold.set_tss_tag(tssTag: "testing")
        let factorKey = try PrivateKey.generate();
        let factorPub = try factorKey.toPublic()
        print(factorPub.count)

        try threshold.create_tagged_tss_share(deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2)
        
        let ( tss_index, tss_share) = try threshold.get_tss_share(factorKey: factorKey.hex)
        
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
        
        // Try get testing tss tag share on Instance 2
        try await threshold2.set_tss_tag(tssTag: "testing")
        let ( tss_index2, tss_share2) = try threshold2.get_tss_share(factorKey: factorKey.hex)

        XCTAssertEqual(tss_share, tss_share2)
        
        
        
        let newFactorKey = try PrivateKey.generate();
        let newFactorPub = try newFactorKey.toPublic()
        // 2/2 -> 2/3 tss
        try await threshold.generate_tss_share(input_tss_share: tss_share, tss_input_index: Int32(tss_index)!, auth_signatures: signatures, new_factor_pub: newFactorPub, new_tss_index: 3)
        let (tss_index3, tss_share3) = try threshold.get_tss_share(factorKey: newFactorKey.hex)
        
        
    }
    
    
    func test_TssModule() async throws {
        let nodeManager = NodeDetailManager(network: .sapphire(.SAPPHIRE_DEVNET))
        let nodeDetail = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL)
        let torusUtils = TorusUtils(serverTimeOffset: 1000, network: .sapphire(.SAPPHIRE_DEVNET), metadataHost: "https://sapphire-dev-2-1.authnetwork.dev/metadata" )
        
        let idToken = try generateIdToken(email: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        let retrievedShare = try await torusUtils.retrieveShares(endpoints: nodeDetail.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: idToken)
        print (retrievedShare)
        let signature = retrievedShare.sessionTokenData
        let signatures = try signature.map{ item in
            guard let sig = item?.signature else {
                throw RuntimeError("fail to get signature")
            }
            return sig
        }
        
        let postbox_key = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox_key.hex, useTss: true, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, nodeDetails: nodeDetail, torusUtils: torusUtils)
        let rss_comm = try RssComm()
        threshold = try! ThresholdKey(
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
        print(share)
        
        let tssTag = "testing"
        let tss1 = try await TssModule(threshold_key: threshold, tss_tag: tssTag)
        let factorKey = try PrivateKey.generate();
        let factorPub = try factorKey.toPublic()
        print(factorPub.count)

        try tss1.create_tagged_tss_share(deviceTssShare: nil, factorPub: factorPub, deviceTssIndex: 2)
        
        let ( tss_index, tss_share) = try tss1.get_tss_share(factorKey: factorKey.hex)
        
        try await threshold.sync_local_metadata_transistions()
        
        
        let newFactorKey = try PrivateKey.generate();
        let newFactorPub = try newFactorKey.toPublic()
        // 2/2 -> 2/3 tss
        try await tss1.generate_tss_share(input_tss_share: tss_share, tss_input_index: Int32(tss_index)!, auth_signatures: signatures, new_factor_pub: newFactorPub, new_tss_index: 3)
        let (tss_index3, tss_share3) = try tss1.get_tss_share(factorKey: newFactorKey.hex)
        
        let (_, tss_share_updated) = try tss1.get_tss_share(factorKey: factorKey.hex)
        
        // after refresh (generate new share), existing tss_share is not valid anymore, new tss share1 is return
        XCTAssertNotEqual(tss_share, tss_share_updated)
        XCTAssertNotEqual(tss_share_updated, tss_share3)
        XCTAssertNotEqual(tss_index, tss_index3)
        
        
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
        
        // Try get testing tss tag share on Instance 2
        let tss2 = try await TssModule(threshold_key: threshold2, tss_tag: tssTag)

        let ( tss_index2, tss_share2) = try tss2.get_tss_share(factorKey: factorKey.hex)
        
        XCTAssertNotEqual(tss_share, tss_share2)
        XCTAssertEqual(tss_share_updated, tss_share2)
        XCTAssertEqual(tss_index, tss_index2)
        
        let ( tss_index2_3, tss_share2_3) = try tss2.get_tss_share(factorKey: newFactorKey.hex)

        XCTAssertEqual(tss_share3, tss_share2_3)
        XCTAssertEqual(tss_index3, tss_index2_3)
        

        
        // 2/3 -> 2/2 tss
        try await tss1.delete_tss_share(input_tss_share: tss_share3, tss_input_index: Int32(tss_index3)!, auth_signatures: signatures, factor_pub: newFactorPub)
        XCTAssertThrowsError( try tss1.get_tss_share(factorKey: newFactorKey.hex) )
        
        let ( tss_index_updated2, tss_share_updated2) = try await tss1.get_tss_share(factorKey: factorKey.hex)
        
        
        
        XCTAssertEqual(tss_index_updated2, tss_index)
        
        XCTAssertNotEqual(tss_share, tss_share_updated2)
        XCTAssertNotEqual(tss_share_updated, tss_share_updated2)
        
    }
    
}


