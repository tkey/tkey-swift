import XCTest
import Foundation
@testable import tkey_pkg
import Foundation

final class tkey_pkgTssOptionsTests: XCTestCase {
    func test_create() {
        let auth_sigs = "[]"
        let selected_servers = "[1,2,3,4,5]"
        let device_tss_share = "930f4193f6e0419110989ddb579016d7a2aefeab093942ec3c2267be492fd72c"
        let tss_input_index: Int32 = 2
        let new_input_index: Int32 = 3
        let factor_pub = try! KeyPoint(x: "c7d2a7f17a2626c9b9d007444b6398ca3fd9d5ff0573c1cc91a7538ab108e2f3", y: "ad52b786c3ad242689fe254f6124cae4b06cf2ceae3705fca376907e1bb52011")
        let new_factor_pub = try! KeyPoint(x: "28ea8d902f86b021e263e4190d74beda39cc315a427e63a9eba76af3c3bc09f0", y: "9ae25585f10ab7f1f32b239fc508d603a89d6a1a88744937b2dd6f6adc930a9a")
        let _ = try! TssOptions(input_tss_share: device_tss_share, tss_input_index: tss_input_index, auth_signatures: auth_sigs, factor_pub: factor_pub,  selected_servers: selected_servers, new_tss_index: new_input_index, new_factor_pub: new_factor_pub)
        let _ = try! TssOptions(input_tss_share: device_tss_share, tss_input_index: tss_input_index, auth_signatures: auth_sigs, factor_pub: factor_pub)
    }
}
