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
    @_transparent
    static func - (lhs: Self, rhs: Magnitude) -> Self
    {
        return Self(xMagnitude: lhs.xMagnitude - rhs, yMagnitude: lhs.yMagnitude - rhs)
    }
    
    @_transparent
    static func - <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return Self(xMagnitude: lhs.xMagnitude - rhs.xMagnitude, yMagnitude: lhs.yMagnitude - rhs.yMagnitude)
    }
    
    @_transparent
    static func -= (lhs: inout Self, rhs: Magnitude)
    {
        lhs = lhs - rhs
    }
    
    @_transparent
    static func -= <T>(lhs: inout Self, rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        lhs = lhs - rhs
    }
    
    @_transparent
    static func + (lhs: Self, rhs: Magnitude) -> Self
    {
        return Self(xMagnitude: lhs.xMagnitude + rhs, yMagnitude: lhs.yMagnitude + rhs)
    }
    
    @_transparent
    static func + <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        return Self(xMagnitude: lhs.xMagnitude + rhs.xMagnitude, yMagnitude: lhs.yMagnitude + rhs.yMagnitude)
    }
    
    @_transparent
    static func += (lhs: inout Self, rhs: Magnitude)
    {
        lhs = lhs + rhs
    }
    
    @_transparent
    static func += <T>(lhs: inout Self, rhs: T) where T: Numeric2D, T.Magnitude == Self.Magnitude
    {
        lhs = lhs + rhs
    }
}
