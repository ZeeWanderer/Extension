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

@inlinable
internal func p_gcd<M: BinaryInteger>(_ m: M, _ n: M) -> M
{
    var lhs = m
    var rhs = n
    while rhs != 0 {
        (lhs, rhs) = (rhs, lhs % rhs)
    }
    return lhs
}

/// Greatest nonnegative common divisor. The result must be representable by `T`.
@inlinable
public func greatestCommonDivisor<T>(_ m: T, _ n: T) -> T where T: BinaryInteger
{
    guard let result = T(exactly: p_gcd(m.magnitude, n.magnitude)) else {
        preconditionFailure("The nonnegative GCD is not representable by \(T.self)")
    }
    return result
}

/// Greatest Common Divisor of an array of integers (GCD also known as Greatest Common Factor or GCF).
/// An empty array returns zero. The final result must be representable by `T`.
@inlinable
public func greatestCommonDivisor<T>(_ arr: [T]) -> T where T: BinaryInteger
{
    let magnitude = arr.reduce(T.Magnitude.zero) { p_gcd($0, $1.magnitude) }
    guard let result = T(exactly: magnitude) else {
        preconditionFailure("The nonnegative GCD is not representable by \(T.self)")
    }
    return result
}

/// Least Common Multiple of 2 integers (LCM).
@inlinable
public func leastCommonMultiple<T>(_ m: T, _ n: T) -> T where T: BinaryInteger
{
    guard m != 0, n != 0 else { return 0 }

    let divisor = p_gcd(m.magnitude, n.magnitude)
    let magnitude = (m.magnitude / divisor) * n.magnitude
    guard let result = T(exactly: magnitude) else {
        preconditionFailure("The nonnegative LCM is not representable by \(T.self)")
    }
    return result
}

/// Lowest Terms of a fraction.
/// - Parameter numerator: Numerator of the fraction.
/// - Parameter denominator: Denominator of the fraction.
@_transparent
public func lowestTerms<T>(numerator: T, denominator: T) -> (T, T) where T: BinaryInteger
{
    let magnitude = p_gcd(numerator.magnitude, denominator.magnitude)
    // When only the negative divisor fits, both inputs are zero or that divisor.
    let gcd = T(exactly: magnitude) ?? min(numerator, denominator)
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
