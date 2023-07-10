import Foundation

public struct RuntimeError: Error {
    public let message: String

    /// Instantiate a `RuntimeError`
    ///
    /// - Parameters:
    ///   - message: The error description.
    ///
    /// - Returns: `RuntimeError`
    public init(_ message: String) {
        self.message = message
    }

    /// Retrieves the error message.
    ///
    /// - Returns: `String`
    public var localizedDescription: String {
        return message
    }
}
