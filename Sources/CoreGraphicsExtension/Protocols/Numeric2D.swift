//
//  Numeric2D.swift
//  Extension
//
//  Created by zee wanderer on 12.11.2024.
//


import SwiftExtension
import CoreGraphics

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
