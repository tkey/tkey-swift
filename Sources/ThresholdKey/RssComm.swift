import Foundation
#if canImport(lib)
import lib
#endif

public final class RssComm {
    private(set) var pointer: OpaquePointer?

    // This is a placeholder to satisfy the interface,
    // tracking this object is not necessary in swift as it maintains context
    // on entry for the callback
    private var obj_ref: UnsafeMutableRawPointer?

    public static func percentEscapeString( string: String ) -> String {
      var characterSet = CharacterSet.alphanumerics
      characterSet.insert(charactersIn: "-.* ")

      return string
        .addingPercentEncoding(withAllowedCharacters: characterSet)!
        .replacingOccurrences(of: " ", with: "+")
        .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
    }

    public init() throws {
        var errorCode: Int32 = -1

        let network_interface: (@convention(c) (UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<CChar>?, UnsafeMutableRawPointer?, UnsafeMutablePointer<Int32>?) -> UnsafeMutablePointer<CChar>?)? = {url, data, _, error_code in
            let sem = DispatchSemaphore.init(value: 0)
            let urlString = String.init(cString: url!)
            let dataString = String.init(cString: data!)
            string_free(url)
            string_free(data)
            let url = URL(string: urlString)!
            let session = URLSession.shared
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("*", forHTTPHeaderField: "Access-Control-Allow-Origin")
            request.addValue("GET, POST", forHTTPHeaderField: "Access-Control-Allow-Methods")
            request.addValue("Content-Type", forHTTPHeaderField: "Access-Control-Allow-Headers")

            if urlString.split(separator: "/").last == "bulk_set_stream" {
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

                let json = try! JSONSerialization.jsonObject(with: dataString.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [[String: Any]]

                var form_data: [String] = []

                for (index, element) in json.enumerated() {
                    let json_elem = try! JSONSerialization.data(withJSONObject: element, options: .withoutEscapingSlashes)
                    let json_escaped_string = RssComm.percentEscapeString(string: String(data: json_elem, encoding: .utf8)!)
                    let final_string = String(index) + "=" + json_escaped_string
                    form_data.append(final_string)
                }
                let body_data = form_data.joined(separator: "&")

                request.httpBody = body_data.data(using: String.Encoding.utf8)
            } else {
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = dataString.data(using: String.Encoding.utf8)
            }
            var resultPointer = UnsafeMutablePointer<CChar>(nil)
            var result = NSString()
            session.dataTask(with: request) { data, _, error in
                defer {
                    sem.signal()
                }
                if error != nil {
                    let code: Int32 = 1
                    error_code?.pointee = code
                }
                if let data = data {
                    let resultString: String = String(decoding: data, as: UTF8.self)
                    result = NSString(string: resultString)

                }
            }.resume()

            sem.wait()
            resultPointer = UnsafeMutablePointer<CChar>(mutating: result.utf8String)
            return resultPointer
        }

        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            rss_comm(network_interface, obj_ref,   error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in RssComm")
            }
        pointer = result
    }

    deinit {
        _ = rss_comm_free(pointer)
    }
}
