import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgSeedPhraseModuleTests: XCTestCase {
    private var thresholdKey: ThresholdKey!

    override func setUp() async throws {
        let postboxKey = try! PrivateKey.generate()
        let storageLayer = try! StorageLayer(enableLogging: true, hostUrl: "https://metadata.tor.us", serverTimeOffset: 2)
        let serviceProvider = try! ServiceProvider(enableLogging: true, postboxKey: postboxKey.hex)
        let threshold = try! ThresholdKey(
            storageLayer: storageLayer,
            serviceProvider: serviceProvider,
            enableLogging: true,
            manualSync: false
        )

        _ = try! await threshold.initialize()
        _ = try! await threshold.reconstruct()
        thresholdKey = threshold
    }

    override func tearDown() {
        thresholdKey = nil
    }

    func test() async {
        let seedPhraseToSet = "seed sock milk update focus rotate barely fade car face mechanic mercy"
        let seedPhraseToSet2 = "object brass success calm lizard science syrup planet exercise parade honey impulse"
        let seedResult = try! SeedPhraseModule.get_seed_phrases(thresholdKey: thresholdKey)
        XCTAssertEqual(seedResult.count, 0 )
        try! await SeedPhraseModule.set_seed_phrase(thresholdKey: thresholdKey, format: "HD Key Tree", phrase: seedPhraseToSet, numberOfWallets: 0)
        let seedResult_2 = try! SeedPhraseModule.get_seed_phrases(thresholdKey: thresholdKey)
        XCTAssertEqual(seedResult_2[0].seedPhrase, seedPhraseToSet )
        try! await SeedPhraseModule.delete_seed_phrase(thresholdKey: thresholdKey, phrase: seedPhraseToSet)
        try! await SeedPhraseModule.set_seed_phrase(thresholdKey: thresholdKey, format: "HD Key Tree", phrase: seedPhraseToSet2, numberOfWallets: 0)
        let seedResult_3 = try! SeedPhraseModule.get_seed_phrases(thresholdKey: thresholdKey)
        XCTAssertEqual(seedResult_3[0].seedPhrase, seedPhraseToSet2 )
        try! await SeedPhraseModule.set_seed_phrase(thresholdKey: thresholdKey, format: "HD Key Tree", phrase: nil, numberOfWallets: 0)
        let seedResult_4 = try! SeedPhraseModule.get_seed_phrases(thresholdKey: thresholdKey)
        XCTAssertEqual(seedResult_4.count, 2)
        try! await SeedPhraseModule.change_phrase(thresholdKey: thresholdKey, oldPhrase: seedPhraseToSet2, newPhrase: seedPhraseToSet)
        let tkey_store = try! thresholdKey.get_tkey_store(moduleName: "seedPhraseModule")
        let id = tkey_store[0]["id"] as! String
        let item = try! thresholdKey.get_tkey_store_item(moduleName: "seedPhraseModule", id: id)["seedPhrase"] as! String
        XCTAssertEqual(seedPhraseToSet, item)
    }
}
