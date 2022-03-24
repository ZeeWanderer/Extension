//
//  Basic.swift
//  
//
//  Created by Maksym Kulyk on 09.03.2022.
//

import Foundation

// MARK: - Math

public extension Comparable
{
    @inline(__always)
    func clamped(to limits: ClosedRange<Self>) -> Self
    {
        return clamp(self, to: limits)
    }
    
    @inline(__always)
    func clamped(min: Self, max: Self) -> Self
    {
        return clamp(self, min: min, max: max)
    }
}

public extension Numeric
{
    @inline(__always)
    func lerped(min: Self, max: Self) -> Self
    {
        return lerp(self, min: min, max: max)
    }
}

// MARK: - Classes
public extension String
{
    @inlinable
    func condenseWhitespace() -> String
    {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter
        {
            !$0.isEmpty
        }.joined(separator: " ")
    }
}
