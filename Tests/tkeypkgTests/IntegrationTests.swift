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
        
        let postbox_key = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox_key.hex, useTss: true, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, nodeDetails: nodeDetail, torusUtils: torusUtils)
        threshold = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
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
        
        // 2/2 -> 2/3 tss
//        let new_tss_share = try await threshold.generate_tss_share(input_tss_share: <#T##String#>, tss_input_index: <#T##Int32#>, auth_signatures: <#T##String#>, factor_pub: <#T##KeyPoint#>)
        
        threshold2 = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
        )
        
        _ = try! await threshold2.initialize()
        try! await threshold2.input_share(share: share, shareType: nil)
        _ = try! await threshold2.reconstruct()
        
        let ( tss_index2, tss_share2) = try threshold2.get_tss_share(factorKey: factorKey.hex)
        XCTAssertEqual(tss_share, tss_share2)
        
        
        
    }
    
    
}

