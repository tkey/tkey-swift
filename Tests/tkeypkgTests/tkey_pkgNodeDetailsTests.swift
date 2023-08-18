import XCTest
import Foundation
@testable import tkey_pkg

final class tkey_pkgNodeDetailsTests: XCTestCase {
    func test_create() {
        _ = try! NodeDetails(server_endpoints: "[\"1\",\"2\",\"3\",\"4\",\"5\"]", server_public_keys: "[{\"x\":\"c7d2a7f17a2626c9b9d007444b6398ca3fd9d5ff0573c1cc91a7538ab108e2f3\",\"y\":\"ad52b786c3ad242689fe254f6124cae4b06cf2ceae3705fca376907e1bb52011\"},{\"x\":\"28ea8d902f86b021e263e4190d74beda39cc315a427e63a9eba76af3c3bc09f0\",\"y\":\"9ae25585f10ab7f1f32b239fc508d603a89d6a1a88744937b2dd6f6adc930a9a\"},{\"x\":\"3bd25da1442d379bc5b2459528bbf36472a112db15913f02850f1615f5cce528\",\"y\":\"835611b4289d58d418d7941d8e2d7107bf4ee9349c0ec4fbef4364293860ed80\"},{\"x\":\"4e226590af4deddf3475767236c2df306a40f5af230effad4ca63326d1767b98\",\"y\":\"5243516fe33c76422b70c575188c92461c6ec6090dbbcf1299ca376a0100cc65\"},{\"x\":\"b7af93af08c3b14087584f6f542e49df930788935bbb58ee1126f00e4dcde3f1\",\"y\":\"90363cc4a3b14c929103fdd6db41bf5777564311c7ba00f778f17a6f9004a6d5\"}]", serverThreshold: 3)
    }
}
