import XCTest
import Foundation
@testable import tkey_swift
import Foundation

final class tkey_pkgPrivateKeyTests: XCTestCase {
    func test_generate() {
        let key = try! PrivateKey.generate()
        XCTAssertNotEqual(key.hex.count, 0)
        let key2 = PrivateKey.init(hex: key.hex)
        XCTAssertEqual(key.hex, key2.hex)
    }
}
