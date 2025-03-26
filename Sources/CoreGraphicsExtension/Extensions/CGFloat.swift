//
//  CGFloat.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

public extension CGFloat
{
    /// linear intepolate a point between `min` and `max` with `self` as `parameter` (t).
    /// See: ``lerp(_:min:max:)-2nn16``
    @inlinable
    @inline(__always)
    func lerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(min: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self
    {
        return lerp(self, min: min, max: max)
    }
    
    /// linear intepolate a point between `min` and `max` with `self` as `parameter` (t).
    /// See: ``lerp(_:min:max:)-lglu``
    @inlinable
    @inline(__always)
    func lerped<T: Numeric2D>(min: T, max: T) -> T
    where T.Magnitude: Real, T.Magnitude == Self
    {
        return lerp(self, min: min, max: max)
    }
    
    /// inverse linear intepolate a point between `min` and `max` with `self` as `parameter` (t).
    /// See:  ``ilerp(_:min:max:)-59add``
    @inlinable
    @inline(__always)
    func ilerped<A: Numeric2D, B: Numeric2D, R: Numeric2D>(min: A, max: B) -> R
    where A.Magnitude: Real, B.Magnitude : Real, R.Magnitude: Real,
          A.Magnitude == B.Magnitude, A.Magnitude == R.Magnitude, A.Magnitude == Self
    {
        return ilerp(self, min: min, max: max)
    }
    
    /// inverse linear intepolate a point between `min` and `max` with `self` as `parameter` (t).
    /// See:  ``ilerp(_:min:max:)-59add``
    @inlinable
    @inline(__always)
    func ilerped<T: Numeric2D>(min: T, max: T) -> T
    where T.Magnitude: Real, T.Magnitude == Self
    {
        return ilerp(self, min: min, max: max)
    }
}
