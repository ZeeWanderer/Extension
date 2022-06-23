//
//  Math.swift
//  
//
//  Created by Maksym Kulyk on 18.03.2022.
//

import RealModule

/// Clamp `value` to `[min,max]`
@inlinable
@inline(__always)
public func clamp<T>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable
{
    return min(max(value, minValue), maxValue)
}

/// Clamp `value` to provided `limits`
@inlinable
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
@inlinable
@inline(__always)
public func lerp<T>(_ parameter: T, min: T, max: T) -> T where T: Real
{
    return min + (parameter * (max - min))
}

/// Inverse Linear interpolate value in `[min,max]` with `parameter`.
/// - Precondition: `parameter` in `[min,max]`
/// - Note: May be imprecise due to floating point rounding. Precision depends on operand type.
/// ---
/// # Formula
/// `(parameter - min) / (max - min)`
@inlinable
@inline(__always)
public func ilerp<T>(_ parameter: T, min: T, max: T) -> T where T: Real
{
    return (parameter - min) / (max - min)
}

@inlinable
@inline(__always)
public func greatestCommonFactor<T>(_ m: T, _ n: T) -> T where T: BinaryInteger
{
    var b = max(m, n)
    var r = min(m, n)
    
    while r != 0
    {
        (r, b) = (b, r)
        r = r % b
    }
    
    return b
}

@inlinable
@inline(__always)
public func greatestCommonFactor<T>(_ arr: [T]) -> T where T: BinaryInteger
{
    let result = arr.reduce(0) {greatestCommonFactor($0,$1)}
    return result
}

@inlinable
@inline(__always)
public func leastCommonMultiple<T>(_ m: T, _ n: T) -> T where T: BinaryInteger
{
    return m * n / greatestCommonFactor(m, n)
}

@inlinable
@inline(__always)
public func lowestTerms<T>(numerator: T, denominator: T) -> (T, T) where T: BinaryInteger
{
    let gcf = greatestCommonFactor(numerator, denominator)
    return (numerator / gcf, denominator / gcf)
}
