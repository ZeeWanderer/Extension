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
    /// Clamp `self` to `[min,max]`
    /// See: ``clamp(_:min:max:)``
    @inline(__always)
    func clamped(min: Self, max: Self) -> Self
    {
        return clamp(self, min: min, max: max)
    }
    
    /// Clamp `self` to  to provided `limits`
    /// See: ``clamp(_:to:)``
    @inline(__always)
    func clamped(to limits: ClosedRange<Self>) -> Self
    {
        return clamp(self, to: limits)
    }
}

public extension Numeric
{
    /// Linear interpolate value in `[min,max]` with `self` for `parameter`.
    /// See: ``lerp(_:min:max:)``
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
