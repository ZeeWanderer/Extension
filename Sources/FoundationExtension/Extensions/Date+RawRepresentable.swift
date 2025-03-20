//
//  Date+RawRepresentable.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

extension Date: @retroactive RawRepresentable
{
    @inlinable
    public var rawValue: TimeInterval
    {
        Date.timeIntervalSinceReferenceDate
    }
    
    @inlinable
    public init?(rawValue: TimeInterval)
    {
        self = Date(timeIntervalSinceReferenceDate: rawValue)
    }
}


