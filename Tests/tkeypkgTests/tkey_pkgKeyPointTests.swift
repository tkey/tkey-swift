import XCTest
import Foundation
@testable import tkey_swift
import Foundation

final class tkey_pkgKeyPointTests: XCTestCase {
    private var data: KeyPoint!
    
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

        let key_details = try! await threshold.initialize()
        data = key_details.pub_key
    }
    
    override func tearDown() {
        data = nil
    }
    
    func test_get_x() {
        XCTAssertNotEqual(try! data.getX().count,0)
    }
    
    func test_get_y() {
        XCTAssertNotEqual(try! data.getY().count,0)
    }
    
    func test_required_shares() {
        XCTAssertNotEqual(try data.getPublicKey(format: .EllipticCompress).count,0)
    }
    
    func test_create_x_y() {
        let point = try! KeyPoint(x: try! data.getX(), y: try! data.getY())
        XCTAssertEqual(try! point.getX(), try! data.getX())
        XCTAssertEqual(try! point.getY(), try! data.getY())
    }
}
