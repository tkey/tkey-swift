import Foundation
#if canImport(lib)
    import lib
#endif

public final class StorageLayer {
    private(set) var pointer: OpaquePointer?
    
    // This is a placeholder to satisfy the interface,
    // tracking this object is not necessary in swift as it maintains context
    // on entry for the callback
    private var obj_ref: UnsafeMutableRawPointer?

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
    ///   - enable_logging: Determines whether logging is enabled or not (pending).
    ///   - host_url: Url for the metadata server.
    ///   - server_time_offset: Timezone offset for the metadata server.
    ///
    /// - Returns: `StorageLayer`
    ///
    /// - Throws: `RuntimeError`, indicates invalid parameters.
    public init(enable_logging: Bool, host_url: String, server_time_offset: Int64) throws {
        var errorCode: Int32 = -1
        let urlPointer = UnsafeMutablePointer<Int8>(mutating: (host_url as NSString).utf8String)

        let network_interface: (@convention(c) (UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<CChar>?, UnsafeMutableRawPointer?, UnsafeMutablePointer<Int32>?) -> UnsafeMutablePointer<CChar>?)? = {url, data, obj_ref, error_code in
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
                let boundary = "Boundary-\(UUID().uuidString)"
                request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

                let json = try! JSONSerialization.jsonObject(with: dataString.data(using: String.Encoding.utf8)!, options: .allowFragments) as! [[String: Any]]
                
                var body_data = Data()
                
                for (index, item) in json.enumerated() {
                    body_data.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body_data.append("Content-Disposition: form-data; name=\"\(index)\"\r\n\r\n".data(using: .utf8)!)
                     
                    let dataItem = String(data: try! JSONSerialization.data(withJSONObject: item), encoding: .utf8)!
                    body_data.append("\(dataItem)\r\n".data(using: .utf8)!)
                }
                body_data.append("--\(boundary)--\r\n".data(using: .utf8)!)
                
                request.httpBody = body_data
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
            storage_layer(enable_logging, urlPointer, server_time_offset, network_interface, obj_ref,  error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in StorageLayer")
            }
        pointer = result
    }

    deinit {
        let _ = storage_layer_free(pointer)
    }
}
