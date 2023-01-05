//
//  RuntimeError.swift
//  tkey_ios
//
//  Created by David Main on 2022/10/25.
//

import Foundation

public struct RuntimeError: Error {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}
