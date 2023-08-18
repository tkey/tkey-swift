import Foundation
#if canImport(lib)
    import lib
#endif

/*
extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
*/

public final class StorageLayer {
    private(set) var pointer: OpaquePointer?

    // This is a placeholder to satisfy the interface,
    // tracking this object is not necessary in swift as it maintains context
    // on entry for the callback
    private var objRef: UnsafeMutableRawPointer?

    /* for multipart form data
    static func createMultipartBody(data: Data, boundary: String, file: String) -> Data {
          let body = NSMutableData()
          let lineBreak = "\r\n"
          let boundaryPrefix = "--\(boundary)\r\n"
          body.appendString(boundaryPrefix)
          body.appendString("Content-Disposition: form-data; name=\"\(file)\"\r\n")
          body.appendString("Content-Type: \("application/json;charset=utf-8")\r\n\r\n")
          body.append(data)
          body.appendString("\r\n")
          body.appendString("--\(boundary)--\(lineBreak)")
          return body as Data
      }
     */

    private static func percentEscapeString( string: String ) -> String {
      var characterSet = CharacterSet.alphanumerics
      characterSet.insert(charactersIn: "-.* ")

      return string
        .addingPercentEncoding(withAllowedCharacters: characterSet)!
        .replacingOccurrences(of: " ", with: "+")
        .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
    }

    /// Instantiate a `StorageLayer` object,
    ///
    /// - Parameters:
    ///   - enableLogging: Determines whether logging is enabled or not (pending).
    ///   - hostUrl: Url for the metadata server.
    ///   - serverTimeOffset: Timezone offset for the metadata server.
    ///
    /// - Returns: `StorageLayer`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters.
    public init(enableLogging: Bool, hostUrl: String, serverTimeOffset: Int64) throws {
        var errorCode: Int32 = -1
        let urlPointer = UnsafeMutablePointer<Int8>(mutating: (hostUrl as NSString).utf8String)

        let networkInterface: (@convention(c) (UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<CChar>?,
                                               UnsafeMutableRawPointer?, UnsafeMutablePointer<Int32>?) -> UnsafeMutablePointer<CChar>?)?
        = {url, data, _, errorCode in
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
                // let boundary = UUID().uuidString;
                // request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

                let data = dataString.data(using: String.Encoding.utf8)!
//                else {
//                    let code: Int32 = 1
//                    errorCode?.pointee = code
//                    let result = NSString("")
//                    let resultPointer = UnsafeMutablePointer<CChar>(mutating: result.utf8String)
//                    return resultPointer
//
//                }
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else {
                    let code: Int32 = 1
                    errorCode?.pointee = code
                    let result = NSString("")
                    let resultPointer = UnsafeMutablePointer<CChar>(mutating: result.utf8String)
                    return resultPointer
                }

                // for item in json {
                    // let dataItem = try! JSONSerialization.data(withJSONObject: item, options: .prettyPrinted)
                    // requestData.append(StorageLayer.createMultipartBody(data: dataItem, boundary: boundary, file: "multipartData"))
                // }

                var formData: [String] = []

                // urlencoded item format: "(key)=(self.percentEscapeString(value))"
                for (index, element) in json.enumerated() {
                    let jsonElem = try? JSONSerialization.data(withJSONObject: element, options: .withoutEscapingSlashes)
                    
                    guard let jsonStr = String(data: jsonElem!, encoding: .utf8)
                    else {
                        let code: Int32 = 1
                        errorCode?.pointee = code
                        let result = NSString("")
                        let resultPointer = UnsafeMutablePointer<CChar>(mutating: result.utf8String)
                        return resultPointer
                    }
                    let jsonEscapedString = StorageLayer.percentEscapeString(string: jsonStr )
                    let finalString = String(index) + "=" + jsonEscapedString
                    formData.append(finalString)
                }
                let bodyData = formData.joined(separator: "&")

                request.httpBody = bodyData.data(using: String.Encoding.utf8)
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
                    errorCode?.pointee = code
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
            storage_layer(enableLogging, urlPointer, serverTimeOffset, networkInterface, objRef,    error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in StorageLayer")
            }
        pointer = result
    }

    deinit {
        _ = storage_layer_free(pointer)
    }
}
