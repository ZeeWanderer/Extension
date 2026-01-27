//
//  AdditiveArithmetic2D.swift
//  Extension
//
//  Created by zee wanderer on 12.11.2024.
//


import SwiftExtension
import CoreGraphics

public protocol AdditiveArithmetic2D: Equatable2D where Magnitude: AdditiveArithmetic
{
    static func - (_ lhs: Self, _ rhs: Magnitude) -> Self
    static func - <T>(_ lhs: Self, _ rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    static func -= (_ lhs: inout Self, _ rhs: Magnitude)
    static func -= <T>(_ lhs: inout Self, _ rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    static func + (_ lhs: Self, _ rhs: Magnitude) -> Self
    static func + <T>(_ lhs: Self, _ rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    static func += (_ lhs: inout Self, _ rhs: Magnitude)
    static func += <T>(_ lhs: inout Self, _ rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
}

public extension AdditiveArithmetic2D
{
    @_transparent
    static func - (_ lhs: Self, _ rhs: Magnitude) -> Self
    {
        return Self(xMagnitude: lhs.xMagnitude - rhs, yMagnitude: lhs.yMagnitude - rhs)
    }
    
    @_transparent
    static func - <T>(_ lhs: Self, _ rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return Self(xMagnitude: lhs.xMagnitude - rhs.xMagnitude, yMagnitude: lhs.yMagnitude - rhs.yMagnitude)
    }
    
    @_transparent
    static func -= (_ lhs: inout Self, _ rhs: Magnitude)
    {
        lhs = lhs - rhs
    }
    
    @_transparent
    static func -= <T>(_ lhs: inout Self, _ rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        lhs = lhs - rhs
    }
    
    @_transparent
    static func + (_ lhs: Self, _ rhs: Magnitude) -> Self
    {
        return Self(xMagnitude: lhs.xMagnitude + rhs, yMagnitude: lhs.yMagnitude + rhs)
    }
    
    @_transparent
    static func + <T>(_ lhs: Self, _ rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return Self(xMagnitude: lhs.xMagnitude + rhs.xMagnitude, yMagnitude: lhs.yMagnitude + rhs.yMagnitude)
    }
    
    @_transparent
    static func += (_ lhs: inout Self, _ rhs: Magnitude)
    {
        lhs = lhs + rhs
    }
    
    @_transparent
    static func += <T>(_ lhs: inout Self, _ rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        lhs = lhs + rhs
    }
}
