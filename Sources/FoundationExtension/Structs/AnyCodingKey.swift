//
//  AnyCodingKey.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

public struct AnyCodingKey: CodingKey, Sendable
{
    public var stringValue: String
    public var intValue: Int?
    
    @inlinable
    public init(stringValue: String) { self.stringValue = stringValue; self.intValue = nil }
    
    @inlinable
    public init(intValue: Int) { self.stringValue = "Index \(intValue)"; self.intValue = intValue }
}
