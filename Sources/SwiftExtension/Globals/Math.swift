//
//  Math.swift
//  
//
//  Created by zeewanderer on 18.03.2022.
//

import RealModule

/// Clamp `value` to `[min,max]`
@_transparent
public func clamp<T>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable
{
    return min(max(value, minValue), maxValue)
}

/// Clamp `value` to provided `limits`
@_transparent
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
@_transparent
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
@_transparent
public func ilerp<T>(_ parameter: T, min: T, max: T) -> T where T: Real
{
    return (parameter - min) / (max - min)
}

/// Greatest Common Divisor of 2 integers (GCD also known as Greatest Common Factor or GCF).
@_transparent
public func greatestCommonDivisor<T>(_ m: T, _ n: T) -> T where T: BinaryInteger
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

/// Greatest Common Divisor of an array of integers (GCD also known as Greatest Common Factor or GCF).
/// - Precondition: 2 or more elements in array.
@_transparent
public func greatestCommonDivisor<T>(_ arr: [T]) -> T where T: BinaryInteger
{
    let result = arr.reduce(0) { result, element in
        greatestCommonDivisor(result, element)
    }
    return result
}

/// Least Common Multiple of 2 integers (LCM).
@_transparent
public func leastCommonMultiple<T>(_ m: T, _ n: T) -> T where T: BinaryInteger
{
    return m * n / greatestCommonDivisor(m, n)
}

/// Lowest Terms of a fraction.
/// - Parameter numerator: Numerator of the fraction.
/// - Parameter denominator: Denominator of the fraction.
@_transparent
public func lowestTerms<T>(numerator: T, denominator: T) -> (T, T) where T: BinaryInteger
{
    let gcd = greatestCommonDivisor(numerator, denominator)
    return (numerator / gcd, denominator / gcd)
}

// MARK: - DEPRECATED

/// Greatest Common Factor of 2 integers (GCF also known as Greatest Common Divisor or GCD)
@_transparent
@available(*, unavailable, renamed: "greatestCommonDivisor(_:_:)")
public func greatestCommonFactor<T>(_ m: T, _ n: T) -> T where T: BinaryInteger
{
    return greatestCommonDivisor(m, n)
}

/// Greatest Common Factor of an array of integers (GCF also known as Greatest Common Divisor or GCD)
/// - Precondition: 2 or more elements in array.
@_transparent
@available(*, unavailable, renamed: "greatestCommonDivisor(_:)")
public func greatestCommonFactor<T>(_ arr: [T]) -> T where T: BinaryInteger
{
    return greatestCommonDivisor(arr)
}
