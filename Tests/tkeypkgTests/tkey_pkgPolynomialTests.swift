import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgPolynomialTests: XCTestCase {
    private var data: Polynomial!

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
        data = try! threshold.reconstruct_latest_poly()
    }

    override func tearDown() {
        data = nil
    }

    func test_get_public_polynomial() {
        _ = try! data.getPublicPolynomial()
    }

    func test_generate_shares() {
        let indexes = "[\"c9022864e78c175beb9931ba136233fce416ece4c9af258ac9af404f7436c281\",\"8cd35d2d246e475de2413732c2d134d39bb51a1ed07cb5b1d461b5184c62c1b6\",\"6e0ab0cb7e47bdce6b08c043ee449d94c3addf33968ae79b4c8d7014238c46e4\"]"
        _ = try! data.generateShares(shareIndex: indexes)
    }
}
