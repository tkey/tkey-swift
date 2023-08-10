//
//  File.swift
//  
//
//  Created by CW Lee on 18/07/2023.
//

import Foundation
import XCTest
import Foundation
@testable import tkey_pkg
import TorusUtils

class tkey_baseTests: XCTestCase {
    
    var torus = TorusUtils.init()
        
    override func setUp() async throws {
        let postbox_key = try! PrivateKey.generate()
        let storage_layer = try! StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2)
        let service_provider = try! ServiceProvider(enable_logging: true, postbox_key: postbox_key.hex)
        let threshold = try! ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false
        )

        _ = try! await threshold.initialize()
        _ = try! await threshold.reconstruct()
    }
    
    override func tearDown() {
    }
    

}
