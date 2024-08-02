//
//  Protocols.swift
//  
//
//  Created by Maksym Kulyk on 18.04.2023.
//

import SwiftExtension
import CoreGraphics

// MARK: - Uniform2D
public protocol Uniform2D
{
    associatedtype Magnitude
    
    init(xMagnitude: Magnitude, yMagnitude: Magnitude)
    
    init<T>(_ other: T) where T: Uniform2D, T.Magnitude == Self.Magnitude
    
    var xMagnitude: Magnitude { get mutating set }
    var yMagnitude: Magnitude { get mutating set }
}

public extension Uniform2D
{
    @inlinable
    @inline(__always)
    init<T>(_ other: T) where T: Uniform2D, T.Magnitude == Self.Magnitude
    {
        self.init(xMagnitude: other.xMagnitude, yMagnitude: other.yMagnitude)
    }
}

// MARK: - Equatable2D
public protocol Equatable2D: Uniform2D where Magnitude: Equatable
{
    static func == <T>(lhs: Self, rhs: T) -> Bool where T: Equatable2D, T.Magnitude == Self.Magnitude
    static func != <T>(lhs: Self, rhs: T) -> Bool where T: Equatable2D, T.Magnitude == Self.Magnitude
}

public extension Equatable2D
{
    static func == <T>(lhs: Self, rhs: T) -> Bool where T: Equatable2D, T.Magnitude == Self.Magnitude
    {
        return lhs.xMagnitude == rhs.xMagnitude && lhs.yMagnitude == rhs.yMagnitude
    }
    
    static func != <T>(lhs: Self, rhs: T) -> Bool where T: Equatable2D, T.Magnitude == Self.Magnitude
    {
        return lhs.xMagnitude != rhs.xMagnitude || lhs.yMagnitude != rhs.yMagnitude
    }
}

// MARK: - AdditiveArithmetic2D
public protocol AdditiveArithmetic2D: Equatable2D where Magnitude: AdditiveArithmetic
{
    static func - (lhs: Self, rhs: Magnitude) -> Self
    static func - <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    static func -= (lhs: inout Self, rhs: Magnitude)
    static func -= <T>(lhs: inout Self, rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    static func + (lhs: Self, rhs: Magnitude) -> Self
    static func + <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    static func += (lhs: inout Self, rhs: Magnitude)
    static func += <T>(lhs: inout Self, rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
}

public extension AdditiveArithmetic2D
{
    static func - (lhs: Self, rhs: Magnitude) -> Self
    {
        return Self(xMagnitude: lhs.xMagnitude - rhs, yMagnitude: lhs.yMagnitude - rhs)
    }
    
    static func - <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return Self(xMagnitude: lhs.xMagnitude - rhs.xMagnitude, yMagnitude: lhs.yMagnitude - rhs.yMagnitude)
    }
    
    static func -= (lhs: inout Self, rhs: Magnitude)
    {
        lhs = lhs - rhs
    }
    
    static func -= <T>(lhs: inout Self, rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        lhs = lhs - rhs
    }
    
    static func + (lhs: Self, rhs: Magnitude) -> Self
    {
        return Self(xMagnitude: lhs.xMagnitude + rhs, yMagnitude: lhs.yMagnitude + rhs)
    }
    
    static func + <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return Self(xMagnitude: lhs.xMagnitude + rhs.xMagnitude, yMagnitude: lhs.yMagnitude + rhs.yMagnitude)
    }
    
    static func += (lhs: inout Self, rhs: Magnitude)
    {
        lhs = lhs + rhs
    }
    
    static func += <T>(lhs: inout Self, rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        lhs = lhs + rhs
    }
}

// MARK: - Numeric2D
infix operator .* : MultiplicationPrecedence
public protocol Numeric2D: AdditiveArithmetic2D where Magnitude: Comparable, Magnitude: Numeric
{
    static func * (lhs: Self, rhs: Magnitude) -> Self
    static func * <T>(lhs: Self, rhs: T) -> Magnitude where T: Numeric2D, T.Magnitude == Self.Magnitude
    static func .* <T>(_ lhs: Self, _ rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
}

public extension Numeric2D
{
    @inlinable
    @inline(__always)
    static func * (_ lhs: Self, _ rhs: Magnitude) -> Self
    {
        return .init(xMagnitude:  lhs.xMagnitude * rhs, yMagnitude: lhs.yMagnitude * rhs)
    }
    
    @inlinable
    @inline(__always)
    static func * <T>(lhs: Self, rhs: T) -> Magnitude where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return lhs.xMagnitude * rhs.xMagnitude + lhs.yMagnitude * rhs.yMagnitude
    }
    
    @inlinable
    @inline(__always)
    static func .* <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return .init(xMagnitude: lhs.xMagnitude * rhs.xMagnitude, yMagnitude: lhs.yMagnitude * rhs.yMagnitude)
    }
}

// MARK: Numeric2D - Member variants of static functions
public extension Numeric2D
{
    // SCALE
    @inlinable
    @inline(__always)
    func scaled(x scaleX: Magnitude, y scaleY: Magnitude) -> Self
    {
        return .init(xMagnitude: self.xMagnitude * scaleX, yMagnitude: self.yMagnitude * scaleY)
    }
    
    @inlinable
    @inline(__always)
    func scaled(x scaleX: Magnitude) -> Self
    {
        return .init(xMagnitude: self.xMagnitude * scaleX, yMagnitude: self.yMagnitude)
    }
    
    @inlinable
    @inline(__always)
    func scaled(y scaleY: Magnitude) -> Self
    {
        return .init(xMagnitude: self.xMagnitude, yMagnitude: self.yMagnitude * scaleY)
    }
    
    @inlinable
    @inline(__always)
    func scaled(_ scale: Magnitude) -> Self
    {
        return self * scale
    }
    
    @inlinable
    @inline(__always)
    func scaled<T>(_ scale: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return scaled(x: scale.xMagnitude, y: scale.yMagnitude)
    }
    
    // clamp
    
    /// See ``clamp(_:x:)``
    @inlinable
    @inline(__always)
    func clamped(x range: ClosedRange<Magnitude>) -> Self
    {
        return clamp(self, x: range)
    }
    
    /// See ``clamp(_:y:)``
    @inlinable
    @inline(__always)
    func clamped(y range: ClosedRange<Magnitude>) -> Self
    {
        return clamp(self, y: range)
    }
    
    /// See ``clamp(_:x:y:)``
    @inlinable
    @inline(__always)
    func clamped(x rangeX: ClosedRange<Magnitude>, y rangeY: ClosedRange<Magnitude>) -> Self
    {
        return clamp(self, x: rangeX, y: rangeY)
    }
    
    /// See  ``clamp(_:to:)-u87g
    @inlinable
    @inline(__always)
    func clamped(to range: ClosedRange<Magnitude>) -> Self
    {
        return clamp(self, to: range)
    }
    
    // LI, RLI
    
    /// linear intepolate a point between `min` and `max` with `self` as `parameter`.
    /// See:  ``lerp(_:min:max:)-6esqb``
    @inlinable
    @inline(__always)
    func lerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(min: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return lerp(self, min: min, max: max)
    }
    
    /// linear intepolate a point between `min` and `max` for `parameter`  with `self` as `min`.
    /// See:  ``lerp(_:min:max:)-6esqb``
    @inlinable
    @inline(__always)
    func lerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(_ parameter: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return lerp(parameter, min: self, max: max)
    }
    
    /// linear intepolate a point between `min` and `max` for `parameter`  with `self` as `max`.
    /// See:  ``lerp(_:min:max:)-6esqb``
    @inlinable
    @inline(__always)
    func lerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(_ parameter: A, min: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return lerp(parameter, min: min, max: self)
    }
    
    
    /// inverse linear intepolate a point between `min` and `max` with `self` as `parameter`.
    /// See:  ``ilerp(_:min:max:)-53q91``
    @inlinable
    @inline(__always)
    func ilerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(min: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return ilerp(self, min: min, max: max)
    }
    
    /// inverse linear intepolate a point between `min` and `max` for `parameter`  with `self` as `min`.
    /// See:  ``ilerp(_:min:max:)-53q91``
    @inlinable
    @inline(__always)
    func ilerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(_ parameter: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return ilerp(parameter, min: self, max: max)
    }
    
    /// inverse linear intepolate a point between `min` and `max` for `parameter`  with `self` as `max`.
    /// See:  ``ilerp(_:min:max:)-53q91``
    @inlinable
    @inline(__always)
    func ilerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(_ parameter: A, min: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return ilerp(parameter, min: min, max: self)
    }
}

// MARK: - Numeric2D public functions

@inlinable
@inline(__always)
public func min<T>(_ lhs: T, _ rhs: T) -> T where T: Numeric2D
{
    return T(xMagnitude: min(lhs.xMagnitude, rhs.xMagnitude), yMagnitude: min(lhs.yMagnitude, rhs.yMagnitude))
}

@inlinable
@inline(__always)
public func min<T>(_ scalar: T.Magnitude, _ rhs: T) -> T where T: Numeric2D
{
    return T(xMagnitude: min(scalar, rhs.xMagnitude), yMagnitude: min(scalar, rhs.yMagnitude))
}

@inlinable
@inline(__always)
public func max<T>(_ lhs: T, _ rhs: T) -> T where T: Numeric2D
{
    return T(xMagnitude: max(lhs.xMagnitude, rhs.xMagnitude), yMagnitude: max(lhs.yMagnitude, rhs.yMagnitude))
}

@inlinable
@inline(__always)
public func max<T>(_ scalar: T.Magnitude, _ rhs: T) -> T where T: Numeric2D
{
    return T(xMagnitude: max(scalar, rhs.xMagnitude), yMagnitude: max(scalar, rhs.yMagnitude))
}

// MARK: - SignedNumeric2D
public protocol SignedNumeric2D: Numeric2D where Magnitude: SignedNumeric
{
    static prefix func - (operand: Self) -> Self
    mutating func negate()
}

public extension SignedNumeric2D
{
    @inlinable
    @inline(__always)
    static prefix func - (operand: Self) -> Self
    {
        return Self(xMagnitude: -operand.xMagnitude, yMagnitude: -operand.yMagnitude)
    }
    
    @inlinable
    @inline(__always)
    mutating func negate()
    {
        return self = -self
    }
}

public protocol Hashable2D: Uniform2D, Hashable where Magnitude: Hashable { }

extension Hashable2D where Magnitude: Hashable
{
    @inlinable
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(self.xMagnitude)
        hasher.combine(self.yMagnitude)
    }
}

infix operator ./ : MultiplicationPrecedence
public protocol FloatingPoint2D: SignedNumeric2D, Hashable2D where Magnitude: FloatingPoint
{
    static func / (lhs: Self, rhs: Magnitude) -> Self
    //static func / <T>(lhs: Self, rhs: T) -> Magnitude where T: Numeric2D, T.Magnitude == Self.Magnitude
    static func ./ <T>(_ lhs: Self, _ rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
}

// MARK: - FloatingPoint2D
public extension FloatingPoint2D
{
    @inlinable
    @inline(__always)
    static func / (_ lhs: Self, _ rhs: Magnitude) -> Self
    {
        return .init(xMagnitude:  lhs.xMagnitude / rhs, yMagnitude: lhs.yMagnitude / rhs)
    }
    
//    @inlinable
//    @inline(__always)
//    static func / <T>(lhs: Self, rhs: T) -> Magnitude where T: Numeric2D, T.Magnitude == Self.Magnitude
//    {
//        return lhs.xMagnitude / rhs.xMagnitude + lhs.yMagnitude / rhs.yMagnitude
//    }
    
    @inlinable
    @inline(__always)
    static func ./ <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return .init(xMagnitude: lhs.xMagnitude / rhs.xMagnitude, yMagnitude: lhs.yMagnitude / rhs.yMagnitude)
    }
}

