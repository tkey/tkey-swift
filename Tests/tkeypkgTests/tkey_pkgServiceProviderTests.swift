import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgServiceProviderTests: XCTestCase {
    func test_provider() {
        let key = try! PrivateKey.generate()
        _ = try! ServiceProvider(enable_logging: true, postbox_key: key.hex)
    }
}
