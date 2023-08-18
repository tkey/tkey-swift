import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgStorageLayerTests: XCTestCase {
    func test_storage() {
        let url = "https://metadata.tor.us"
        _ = try! StorageLayer.init(enableLogging: true, hostUrl: url, serverTimeOffset: 2)
    }
}
