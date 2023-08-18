import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgStorageLayerTests: XCTestCase {
    func test_storage() {
        let url = "https://metadata.tor.us"
        _ = try! StorageLayer.init(enable_logging: true, host_url: url, server_time_offset: 2)
    }
}
