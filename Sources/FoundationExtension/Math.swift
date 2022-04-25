//
//  Math.swift
//  
//
//  Created by Maksym Kulyk on 18.03.2022.
//

import Foundation

/// Clamp `value` to `[min,max]`
@inline(__always)
public func clamp<T>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable
{
    return min(max(value, minValue), maxValue)
}

/// Clamp `value` to provided `limits`
@inline(__always)
public func clamp<T>(_ value: T, to limits: ClosedRange<T>) -> T where T: Comparable
{
    return min(max(value, limits.lowerBound), limits.upperBound)
}

/// Linear interpolate value in `[min,max]` with `parameter`.
/// - Precondition: `parameter` in `[0,1]`
/// - Note: May be imprecise due to floating point rounding. Precision depends on operand type.
/// ---
/// # Formula
/// `min + (parameter * (max - min))`
@inline(__always)
public func lerp<T>(_ parameter: T, min: T, max: T) -> T where T: Numeric
{
    return min + (parameter * (max - min))
}

/// Inverse Linear interpolate value in `[min,max]` with `parameter`.
/// - Precondition: `parameter` in `[min,max]`
/// - Note: May be imprecise due to floating point rounding. Precision depends on operand type.
/// ---
/// # Formula
/// `(parameter - min) / (max - min)`
@inline(__always)
public func ilerp<T>(_ parameter: T, min: T, max: T) -> T where T: FloatingPoint
{
    return (parameter - min) / (max - min)
}
