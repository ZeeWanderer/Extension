//
//  Uniform2D.swift
//  Extension
//
//  Created by zee wanderer on 12.11.2024.
//


import SwiftExtension
import CoreGraphics

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
