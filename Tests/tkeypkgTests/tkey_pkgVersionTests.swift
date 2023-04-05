import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgVersionTests: XCTestCase {
    func test_library_version() {
        _ = try! library_version()
    }
}
