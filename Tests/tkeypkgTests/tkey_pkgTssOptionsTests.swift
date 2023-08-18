import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgTssOptionsTests: XCTestCase {
    func test_create() {
        let auth_sigs: [String] = []
        let selected_servers = "[1,2,3,4,5]"
        let device_tss_share = "930f4193f6e0419110989ddb579016d7a2aefeab093942ec3c2267be492fd72c"
        let tss_input_index: Int32 = 2
        let new_input_index: Int32 = 3
        let factor_pub = try! KeyPoint(valueX: "c7d2a7f17a2626c9b9d007444b6398ca3fd9d5ff0573c1cc91a7538ab108e2f3", valueY: "ad52b786c3ad242689fe254f6124cae4b06cf2ceae3705fca376907e1bb52011")
        let new_factor_pub = try! KeyPoint(valueX: "28ea8d902f86b021e263e4190d74beda39cc315a427e63a9eba76af3c3bc09f0", valueY: "9ae25585f10ab7f1f32b239fc508d603a89d6a1a88744937b2dd6f6adc930a9a")

        _ = try! TssOptions(inputTssShare: device_tss_share, tssInputIndex: tss_input_index, authSignatures: auth_sigs, factorPub: factor_pub,   selectedServers: selected_servers, newTssIndex:  new_input_index, newFactorPub: new_factor_pub)
        _ = try! TssOptions(inputTssShare: device_tss_share, tssInputIndex: tss_input_index, authSignatures: auth_sigs, factorPub: factor_pub)
    }
}
