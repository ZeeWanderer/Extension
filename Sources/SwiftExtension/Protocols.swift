//
//  Protocols.swift
//  
//
//  Created by Maksym Kulyk on 04.05.2022.
//

import RealModule

// MARK: - Math
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

public extension Real
{
    /// Linear interpolate value in `[min,max]` with `self` for `parameter`.
    /// See: ``lerp(_:min:max:)``
    @inlinable
    @inline(__always)
    func lerped(min: Self, max: Self) -> Self
    {
        return lerp(self, min: min, max: max)
    }
    
    /// Inverse Linear interpolate value in `[min,max]` with `self` for `parameter`.
    /// See: ``ilerp(_:min:max:)``
    @inlinable
    @inline(__always)
    func ilerped(min: Self, max: Self) -> Self
    {
        return ilerp(self, min: min, max: max)
    }
}
