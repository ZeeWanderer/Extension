//
//  Array+RawRepresentable.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

extension Array: @retroactive RawRepresentable where Element: Codable
{
    @inlinable
    public init?(rawValue: String)
    {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    @inlinable
    public var rawValue: String
    {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
