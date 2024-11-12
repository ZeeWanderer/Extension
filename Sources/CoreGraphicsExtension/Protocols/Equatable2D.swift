//
//  Equatable2D.swift
//  Extension
//
//  Created by zee wanderer on 12.11.2024.
//


import SwiftExtension
import CoreGraphics

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
