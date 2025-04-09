//
//  FloatingPoint2D.swift
//  Extension
//
//  Created by zee wanderer on 12.11.2024.
//


import SwiftExtension
import CoreGraphics

public protocol FloatingPoint2D: SignedNumeric2D, Hashable2D where Magnitude: FloatingPoint
{
    static func / (lhs: Self, rhs: Magnitude) -> Self
    
    static func ./ <T>(_ lhs: Self, _ rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    
    static var nan: Self { get }
    static var signalingNaN: Self { get }
    static var infinity: Self { get }
    static var greatestFiniteMagnitude: Self { get }
    static var pi: Self { get }
    var ulp: Self { get }
    static var ulpOfOne: Self { get }
    static var leastNormalMagnitude: Self { get }
    static var leastNonzeroMagnitude: Self { get }
}

public extension FloatingPoint2D
{
    @_transparent
    static func / (_ lhs: Self, _ rhs: Magnitude) -> Self
    {
        return .init(xMagnitude:  lhs.xMagnitude / rhs, yMagnitude: lhs.yMagnitude / rhs)
    }
    
    @_transparent
    static func ./ <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return .init(xMagnitude: lhs.xMagnitude / rhs.xMagnitude, yMagnitude: lhs.yMagnitude / rhs.yMagnitude)
    }
    
    @inlinable
    @inline(__always)
    static var nan: Self { return Self(xMagnitude: .nan, yMagnitude: .nan) }
    
    @inlinable
    @inline(__always)
    static var signalingNaN: Self { return Self(xMagnitude: .signalingNaN, yMagnitude: .signalingNaN) }
    
    @inlinable
    @inline(__always)
    static var infinity: Self { return Self(xMagnitude: .infinity, yMagnitude: .infinity) }
    
    @inlinable
    @inline(__always)
    static var greatestFiniteMagnitude: Self { return Self(xMagnitude: .greatestFiniteMagnitude, yMagnitude: .greatestFiniteMagnitude) }
    
    @inlinable
    @inline(__always)
    static var pi: Self { return Self(xMagnitude: .pi, yMagnitude: .pi) }
    
    @inlinable
    @inline(__always)
    var ulp: Self { return Self(xMagnitude: xMagnitude.ulp, yMagnitude: yMagnitude.ulp) }
    
    @inlinable
    @inline(__always)
    static var ulpOfOne: Self { return Self(xMagnitude: .ulpOfOne, yMagnitude: .ulpOfOne) }
    
    @inlinable
    @inline(__always)
    static var leastNormalMagnitude: Self { return Self(xMagnitude: .leastNormalMagnitude, yMagnitude: .leastNormalMagnitude) }
    
    @inlinable
    @inline(__always)
    static var leastNonzeroMagnitude: Self { return Self(xMagnitude: .leastNonzeroMagnitude, yMagnitude: .leastNonzeroMagnitude) }
}
