import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgSeedPhraseModuleTests: XCTestCase {
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
        let seedPhraseToSet = "seed sock milk update focus rotate barely fade car face mechanic mercy"
        let seedPhraseToSet2 = "object brass success calm lizard science syrup planet exercise parade honey impulse"
        let seedResult = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult.count, 0 )
        try! await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet, number_of_wallets: 0)
        let seedResult_2 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_2[0].seedPhrase, seedPhraseToSet )
        try! await SeedPhraseModule.delete_seed_phrase(threshold_key: threshold_key, phrase: seedPhraseToSet)
        try! await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: seedPhraseToSet2, number_of_wallets: 0)
        let seedResult_3 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_3[0].seedPhrase, seedPhraseToSet2 )
        try! await SeedPhraseModule.set_seed_phrase(threshold_key: threshold_key, format: "HD Key Tree", phrase: nil, number_of_wallets: 0)
        let seedResult_4 = try! SeedPhraseModule.get_seed_phrases(threshold_key: threshold_key)
        XCTAssertEqual(seedResult_4.count, 2)
        try! await SeedPhraseModule.change_phrase(thresholdKey: threshold_key, old_phrase: seedPhraseToSet2, new_phrase: seedPhraseToSet)
        let tkey_store = try! threshold_key.get_tkey_store(moduleName: "seedPhraseModule")
        let id = tkey_store[0]["id"] as! String
        let item = try! threshold_key.get_tkey_store_item(moduleName: "seedPhraseModule", id: id)["seedPhrase"] as! String
        XCTAssertEqual(seedPhraseToSet, item)
    }
}
