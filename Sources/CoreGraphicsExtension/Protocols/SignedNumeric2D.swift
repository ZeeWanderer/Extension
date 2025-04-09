//
//  SignedNumeric2D.swift
//  Extension
//
//  Created by zee wanderer on 12.11.2024.
//


import SwiftExtension
import CoreGraphics

public protocol SignedNumeric2D: Numeric2D where Magnitude: SignedNumeric
{
    static prefix func - (operand: Self) -> Self
    mutating func negate()
}

public extension SignedNumeric2D
{
    @_transparent
    static prefix func - (operand: Self) -> Self
    {
        return Self(xMagnitude: -operand.xMagnitude, yMagnitude: -operand.yMagnitude)
    }
    
    @_transparent
    mutating func negate()
    {
        return self = -self
    }
}
