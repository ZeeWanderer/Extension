//
//  Date+RawRepresentable.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

extension Date: RawRepresentable
{
    @usableFromInline
    internal static var formatter: ISO8601DateFormatter {
        ISO8601DateFormatter()
    }
    
    @inlinable
    public var rawValue: String
    {
        Date.formatter.string(from: self)
    }
    
    @inlinable
    public init?(rawValue: String)
    {
        self = Date.formatter.date(from: rawValue) ?? Date()
    }
}
