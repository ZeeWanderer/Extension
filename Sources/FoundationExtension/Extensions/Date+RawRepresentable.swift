//
//  Date+RawRepresentable.swift
//  
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation

extension Date: @retroactive RawRepresentable
{
    @inlinable
    public var rawValue: TimeInterval
    {
        self.timeIntervalSinceReferenceDate
    }
    
    @inlinable
    public init?(rawValue: TimeInterval)
    {
        self = Date(timeIntervalSinceReferenceDate: rawValue)
    }
}


