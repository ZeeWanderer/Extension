//
//  Protocols.swift
//  
//
//  Created by Maksym Kulyk on 18.04.2023.
//

import SwiftExtension
import CoreGraphics

public protocol Numeric2D
{
    associatedtype Magnitude : Comparable, Numeric
    
    init(xMagnitude: Magnitude, yMagnitude: Magnitude)
    
    init<T>(_ numeric2d: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    
    var xMagnitude: Magnitude { get }
    var yMagnitude: Magnitude { get }
}

public extension Numeric2D
{
    @inlinable
    @inline(__always)
    init<T>(_ numeric2d: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        self.init(xMagnitude: numeric2d.xMagnitude, yMagnitude: numeric2d.yMagnitude)
    }
    
    /// linear intepolate a point between `min` and `max` with `self` as `parameter`.
    /// See:  ``lerp(_:min:max:)-z0dd``
    @inlinable
    @inline(__always)
    func lerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(min: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return lerp(self, min: min, max: max)
    }
    
    /// linear intepolate a point between `min` and `max` for `parameter`  with `self` as `min`.
    /// See:  ``lerp(_:min:max:)-z0dd``
    @inlinable
    @inline(__always)
    func lerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(_ parameter: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return lerp(parameter, min: self, max: max)
    }
    
    /// linear intepolate a point between `min` and `max` for `parameter`  with `self` as `max`.
    /// See:  ``lerp(_:min:max:)-z0dd``
    @inlinable
    @inline(__always)
    func lerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(_ parameter: A, min: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return lerp(parameter, min: min, max: self)
    }
    
    
    /// inverse linear intepolate a point between `min` and `max` with `self` as `parameter`.
    /// See:  ``ilerp(_:min:max:)-24jcs``
    @inlinable
    @inline(__always)
    func ilerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(min: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return ilerp(self, min: min, max: max)
    }
    
    /// inverse linear intepolate a point between `min` and `max` for `parameter`  with `self` as `min`.
    /// See:  ``ilerp(_:min:max:)-24jcs``
    @inlinable
    @inline(__always)
    func ilerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(_ parameter: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return ilerp(parameter, min: self, max: max)
    }
    
    /// inverse linear intepolate a point between `min` and `max` for `parameter`  with `self` as `max`.
    /// See:  ``ilerp(_:min:max:)-24jcs``
    @inlinable
    @inline(__always)
    func ilerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(_ parameter: A, min: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self.Magnitude
    {
        return ilerp(parameter, min: min, max: self)
    }
}
