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
    
    static var infinity: Self { get }
}

public extension FloatingPoint2D
{
    @inlinable
    @inline(__always)
    static func / (_ lhs: Self, _ rhs: Magnitude) -> Self
    {
        return .init(xMagnitude:  lhs.xMagnitude / rhs, yMagnitude: lhs.yMagnitude / rhs)
    }
    
    @inlinable
    @inline(__always)
    static func ./ <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return .init(xMagnitude: lhs.xMagnitude / rhs.xMagnitude, yMagnitude: lhs.yMagnitude / rhs.yMagnitude)
    }
    
    @inlinable
    @inline(__always)
    static var infinity: Self { return Self(xMagnitude: .infinity, yMagnitude: .infinity) }
}
