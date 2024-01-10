import XCTest
import Foundation
@testable import tkey_swift
import Foundation

final class tkey_pkgShareSerializationModuleTests: XCTestCase {
    private var threshold_key: ThresholdKey!
    
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

        _ = try! await threshold.initialize()
        _ = try! await threshold.reconstruct()
        threshold_key = threshold
    }
    
    override func tearDown() {
        threshold_key = nil
    }
    
    func test() async {
        let share_index = try! await threshold_key.generate_new_share();
        let share = try! threshold_key.output_share(shareIndex: share_index.hex, shareType: "mnemonic")
        let deserialize = try! ShareSerializationModule.deserialize_share(threshold_key: threshold_key, share: share, format: "mnemonic")
        let serialize = try! ShareSerializationModule.serialize_share(threshold_key: threshold_key, share: deserialize, format: "mnemonic")
        XCTAssertEqual(share, serialize)
        
        // share serialization with share, test with nil type format
        let share_index2 = try! await threshold_key.generate_new_share()
        let shareOut = try! threshold_key.output_share(shareIndex: share_index2.hex)
        let phrase2 = try! ShareSerializationModule.serialize_share(threshold_key: threshold_key, share: shareOut)
        let deserializedShare = try! ShareSerializationModule.deserialize_share(threshold_key: threshold_key, share: phrase2)
        XCTAssertEqual(shareOut, deserializedShare)
    }
}
