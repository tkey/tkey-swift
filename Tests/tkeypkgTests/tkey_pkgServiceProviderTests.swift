import XCTest
import Foundation
@testable import tkey
import Foundation

final class tkey_pkgServiceProviderTests: XCTestCase {
    func test_provider() {
        let key = try! PrivateKey.generate()
        let _ = try! ServiceProvider(enable_logging: true, postbox_key: key.hex)
    }
}
