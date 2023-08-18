import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgKeyPointArrayTests: XCTestCase {
    func test_key_point_array() {
        let point_array = KeyPointArray()
        XCTAssertEqual(try! point_array.length(), 0)
        let point = try! KeyPoint(valueX: try! PrivateKey.generate().hex, valueY: try! PrivateKey.generate().hex)
        let point2 = try! KeyPoint(valueX: try! PrivateKey.generate().hex, valueY: try! PrivateKey.generate().hex)
        try! point_array.insert(point: point)
        XCTAssertEqual(try! point_array.length(), 1)
        try! point_array.insert(point: point)
        XCTAssertEqual(try! point_array.length(), 2)
        try! point_array.insert(point: point)
        XCTAssertEqual(try! point_array.length(), 3)
        try! point_array.removeAt(index: 0)
        XCTAssertEqual(try! point_array.length(), 2)
        try! point_array.update(point: point2, index: 1)
        let retrieved_point1 = try! point_array.getAt(index: 0)
        let retrieved_point2 = try! point_array.getAt(index: 1)
        XCTAssertEqual(point, retrieved_point1)
        XCTAssertEqual(point2, retrieved_point2)
        _ = try! point_array.lagrange()
    }
}
