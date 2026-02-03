//
//  RouterPushOptions.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

import SwiftUI

/// Options controlling how router push should behave when the destination already exists in the path.
public struct RouterPushOptions: OptionSet, CustomStringConvertible, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// If the destination exists in path, instead of pushing it again the path is popped to it.
    public static let popToExisting = RouterPushOptions(rawValue: 1 << 0)
    /// Uses flat destination comparison when resolving existing entries.
    public static let flatComparison = RouterPushOptions(rawValue: 1 << 1)
    
    public var description: String {
        let parts: [String] = [
            contains(.popToExisting) ? "popToExisting" : nil,
            contains(.flatComparison) ? "flatComparison" : nil,
        ].compactMap { $0 }
        
        return "[\(parts.joined(separator: ", "))]"
    }
}
