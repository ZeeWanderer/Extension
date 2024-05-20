//
//  Comparable.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import RealModule

public extension Comparable
{
    /// Clamp `self` to `[min,max]`
    /// See: ``clamp(_:min:max:)``
    @inlinable
    @inline(__always)
    func clamped(min: Self, max: Self) -> Self
    {
        return clamp(self, min: min, max: max)
    }
    
    /// Clamp `self` to  to provided `limits`
    /// See: ``clamp(_:to:)``
    @inlinable
    @inline(__always)
    func clamped(to limits: ClosedRange<Self>) -> Self
    {
        return clamp(self, to: limits)
    }
}
