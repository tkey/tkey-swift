//
//  File.swift
//  
//
//  Created by CW Lee on 18/07/2023.
//

import Foundation
import XCTest
@testable import tkey_pkg
import TorusUtils

class tkey_baseTests: XCTestCase {

    var torus = TorusUtils.init()

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
        _ = try! await threshold.reconstruct()
    }

    override func tearDown() {
    }

}
