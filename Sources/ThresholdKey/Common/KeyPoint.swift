import Foundation
#if canImport(lib)
    import lib
#endif

public final class KeyPoint: Equatable {
    public static func == (lhs: KeyPoint, rhs: KeyPoint) -> Bool {
        do {
            let lhsx = try lhs.getX()
            let lhsy = try lhs.getY()
            let rhsx = try rhs.getX()
            let rhsy = try rhs.getY()
            if  lhsx == rhsx && lhsy == rhsy
            {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
    public var pointer: OpaquePointer?
    
    public init(pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    public init(x: String, y: String) throws {
        var errorCode: Int32 = -1
        let xPtr = UnsafeMutablePointer<Int8>(mutating: (x as NSString).utf8String)
        let yPtr = UnsafeMutablePointer<Int8>(mutating: (y as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_new(xPtr, yPtr, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, new")
            }
        pointer = result;
    }
    
    public func getX() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_get_x(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field X")
            }
        let x = String.init(cString: result!)
        string_free(result)
        return x
    }
    
    public func getY() throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_get_y(pointer, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field Y")
            }
        let y = String.init(cString: result!)
        string_free(result)
        return y
    }
    
    public func getAsCompressedPublicKey(format: String) throws -> String {
        var errorCode: Int32 = -1
        
        let encoder_format = UnsafeMutablePointer<Int8>(mutating: ("elliptic-compressed" as NSString).utf8String)
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            key_point_encode(pointer, encoder_format, error)
        })
        guard errorCode == 0 else {
            throw RuntimeError("Error in KeyPoint, field Y")
            }
        let compressed = String.init(cString: result!)
        string_free(result)
        return compressed
    }
    
    deinit {
        key_point_free(pointer)
    }
}
