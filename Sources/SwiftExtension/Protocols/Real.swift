//
//  Real.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import RealModule

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
