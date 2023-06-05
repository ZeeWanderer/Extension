//
//  Basic.swift
//  Extension
//
//  Created by Maksym Kulyk on 9/16/20.
//  Copyright © 2020 max. All rights reserved.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

// MARK: - CGFloat
public extension CGFloat
{
    /// linear intepolate a point between `min` and `max` with `self` as `parameter` (t).
    /// See: ``lerp(_:min:max:)-lglu``
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

extension CGFloat: BinaryRepresentable {}

// MARK: - CGVector
public extension CGVector
{
    @inlinable
    @inline(__always)
    static func * (_ lhs: CGVector, _ rhs: CGFloat) -> CGVector
    {
        return .init(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }
    
    @inlinable
    @inline(__always)
    static func * (_ lhs: CGVector, _ rhs: CGVector) -> CGFloat
    {
        return lhs.dx * rhs.dx + lhs.dy * rhs.dy
    }
    
    @inlinable
    @inline(__always)
    static func / (_ lhs: CGVector, _ rhs: CGFloat) -> CGVector
    {
        return .init(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
    }
    
    @inlinable
    @inline(__always)
    static func + (lhs:CGVector, rhs: CGFloat) -> CGVector
    {
        return .init(dx: lhs.dx + rhs, dy: lhs.dy + rhs)
    }
    
    @inlinable
    @inline(__always)
    static func - (lhs:CGVector, rhs: CGFloat) -> CGVector
    {
        return .init(dx: lhs.dx - rhs, dy: lhs.dy - rhs)
    }
    
    @inlinable
    @inline(__always)
    static func + (lhs:CGVector, rhs: CGVector) -> CGVector
    {
        return .init(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
    
    @inlinable
    @inline(__always)
    static func - (lhs:CGVector, rhs: CGVector) -> CGVector
    {
        return .init(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }
    
    /// See ``clamp(_:dx:)``
    @inlinable
    @inline(__always)
    @available(*, deprecated, renamed: "clamped(x:)")
    func clamped(dx range: ClosedRange<CGFloat>) -> CGVector
    {
        return clamp(self, dx: range)
    }
    
    /// See ``clamp(_:dy:)``
    @inlinable
    @inline(__always)
    @available(*, deprecated, renamed: "clamped(y:)")
    func clamped(dy range: ClosedRange<CGFloat>) -> CGVector
    {
        return clamp(self, dy: range)
    }
    
    /// See ``clamp(_:dx:dy:)``
    @inlinable
    @inline(__always)
    @available(*, deprecated, renamed: "clamped(x:y:)")
    func clamped(dx rangeDx: ClosedRange<CGFloat>, dy rangeDy: ClosedRange<CGFloat>) -> CGVector
    {
        return clamp(self, dx: rangeDx, dy: rangeDy)
    }
}

extension CGVector: Numeric2D
{
    public typealias Magnitude = CGFloat
    
    @inlinable
    @inline(__always)
    public init(xMagnitude: Magnitude, yMagnitude: Magnitude)
    {
        self.init(dx: xMagnitude, dy: yMagnitude)
    }
    
    @inlinable
    @inline(__always)
    public var xMagnitude: Magnitude
    {
        self.dx
    }
    
    @inlinable
    @inline(__always)
    public var yMagnitude: Magnitude
    {
        self.dy
    }
}

extension CGVector: BinaryRepresentable {}

// MARK: - CGPoint
public extension CGPoint
{
    @inlinable
    @inline(__always)
    init(_ vector: CGVector)
    {
        self.init(x: vector.dx, y: vector.dy)
    }
    
    @inlinable
    @inline(__always)
    init(_ size: CGSize)
    {
        self.init(x: size.width, y: size.height)
    }
    
    /// Translate CGPoint by a given ammount
    @inlinable
    @inline(__always)
    func translatedBy(dx: CGFloat, dy: CGFloat) -> CGPoint
    {
        return .init(x:self.x + dx, y:self.y + dy)
    }
    
    /// Translate CGPoint by a vector defined as ((0,0), point)
    @inlinable
    @inline(__always)
    func translated(by point: CGPoint) -> CGPoint
    {
        return .init(x:self.x + point.x, y:self.y + point.y)
    }
    
    /// Translate CGPoint by a vector defined as ((0,0), size)
    @inlinable
    @inline(__always)
    func translated(by size: CGSize) -> CGPoint
    {
        return .init(x:self.x + size.width, y:self.y + size.height)
    }
    
    @inlinable
    @inline(__always)
    static func * (_ lhs: CGPoint, _ rhs: CGFloat) -> CGPoint
    {
        return .init(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    @inlinable
    @inline(__always)
    static func * (_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat
    {
        return lhs.x * rhs.x + lhs.y * rhs.y
    }
    
    @inlinable
    @inline(__always)
    static func * (_ lhs: CGPoint, _ rhs: CGSize) -> CGFloat
    {
        return lhs.x * rhs.width + lhs.y * rhs.height
    }
    
    @inlinable
    @inline(__always)
    static func / (_ lhs: CGPoint, _ rhs: CGFloat) -> CGPoint
    {
        return .init(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    @inlinable
    @inline(__always)
    static func + (lhs:CGPoint, rhs: CGFloat) -> CGPoint
    {
        return .init(x: lhs.x + rhs, y: lhs.y + rhs)
    }
    
    @inlinable
    @inline(__always)
    static func - (lhs:CGPoint, rhs: CGFloat) -> CGPoint
    {
        return .init(x: lhs.x - rhs, y: lhs.y - rhs)
    }
    
    @inlinable
    @inline(__always)
    static func + (lhs:CGPoint, rhs: CGPoint) -> CGPoint
    {
        return .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    @inlinable
    @inline(__always)
    static func - (lhs:CGPoint, rhs: CGPoint) -> CGPoint
    {
        return .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

extension CGPoint: Numeric2D
{
    public typealias Magnitude = CGFloat
    
    @inlinable
    @inline(__always)
    public init(xMagnitude: Magnitude, yMagnitude: Magnitude)
    {
        self.init(x: xMagnitude, y: yMagnitude)
    }
    
    @inlinable
    @inline(__always)
    public var xMagnitude: Magnitude
    {
        self.x
    }
    
    @inlinable
    @inline(__always)
    public var yMagnitude: Magnitude
    {
        self.y
    }
}

extension CGPoint: BinaryRepresentable {}

// MARK: - CGSize
public extension CGSize
{
    @inlinable
    @inline(__always)
    init(side: CGFloat)
    {
        self.init(width: side, height: side)
    }
    
    /// `width * height`
    @inlinable
    @inline(__always)
    var square: CGFloat
    {
        return self.height * self.width
    }
    
    /// Center point of the rectange area defined by `CGSize`
    @inlinable
    @inline(__always)
    var center: CGPoint
    {
        return .init(x: self.width/2.0, y: self.height/2.0)
    }
    
    /// See ``clamp(_:width:)``
    @inlinable
    @inline(__always)
    @available(*, deprecated, renamed: "clamped(x:)")
    func clamped(width range: ClosedRange<CGFloat>) -> CGSize
    {
        return clamp(self, width: range)
    }
    
    /// See ``clamp(_:height:)``
    @inlinable
    @inline(__always)
    @available(*, deprecated, renamed: "clamped(y:)")
    func clamped(height range: ClosedRange<CGFloat>) -> CGSize
    {
        return clamp(self, height: range)
    }
    
    /// See ``clamp(_:width:height:)``
    @inlinable
    @inline(__always)
    @available(*, deprecated, renamed: "clamped(x:y:)")
    func clamped(width rangeWidth: ClosedRange<CGFloat>, height rangeHeight: ClosedRange<CGFloat>) -> CGSize
    {
        return clamp(self, width: rangeWidth, height: rangeHeight)
    }
}

extension CGSize: Numeric2D
{
    public typealias Magnitude = CGFloat
    
    @inlinable
    @inline(__always)
    public init(xMagnitude: Magnitude, yMagnitude: Magnitude)
    {
        self.init(width: xMagnitude, height: yMagnitude)
    }
    
    @inlinable
    @inline(__always)
    public var xMagnitude: Magnitude
    {
        self.width
    }
    
    @inlinable
    @inline(__always)
    public var yMagnitude: Magnitude
    {
        self.height
    }
}

extension CGSize: BinaryRepresentable {}

// MARK: - CGRect
public extension CGRect
{
    @inlinable
    @inline(__always)
    init(origin: CGPoint, side: CGFloat)
    {
        self.init(origin: origin, size: .init(side: side))
    }
    
    @inlinable
    @inline(__always)
    init(x: CGFloat, y: CGFloat, side: CGFloat)
    {
        self.init(x: x, y: y, width: side, height: side)
    }
    
    /// Translate CGRect by a given ammount
    @inlinable
    @inline(__always)
    func translatedBy(dx: CGFloat, dy: CGFloat) -> CGRect
    {
        return .init(origin: self.origin.translatedBy(dx: dx, dy: dy), size: size)
    }
    
    /// Translate CGRect by a vector defined as ((0,0), point)
    @inlinable
    @inline(__always)
    func translated(by point: CGPoint) -> CGRect
    {
        return .init(origin: self.origin.translated(by: point), size: size)
    }
    
    /// Translate CGRect by a vector defined as ((0,0), size)
    @inlinable
    @inline(__always)
    func translated(by size: CGSize) -> CGRect
    {
        return .init(origin: self.origin.translated(by: size), size: size)
    }
    
    // Includes origin into scaling because CGSize describes
    // an are without position, but CGRect describes an area
    // with position.
    @inlinable
    @inline(__always)
    static func * (lhs: CGRect, rhs: CGFloat) -> CGRect
    {
        return .init(origin: lhs.origin * rhs, size: lhs.size * rhs)
    }
    
    /// `width * height`
    @inlinable
    @inline(__always)
    var square: CGFloat
    {
        return self.size.square
    }
    
    /// Center point of the `CGRect`
    /// - Note: With respect to origin
    @inlinable
    @inline(__always)
    var center: CGPoint
    {
        return .init(x: self.midX, y: self.midY)
    }
    
    @inlinable
    @inline(__always)
    var diagonal: CGFloat
    {
        // Opt for squares
        if self.width == self.height { return self.width * CGFloat.root(2.0, 2) }
        
        // Universal path
        return CGFloat.root(CGFloat.pow(self.width, 2) + CGFloat.pow(self.height, 2), 2)
    }
    
    @inlinable
    @inline(__always)
    func scaled(x scaleX: CGFloat, y scaleY: CGFloat) -> CGRect
    {
        return .init(origin: origin.scaled(x: scaleX, y: scaleY), size: size.scaled(x: scaleX, y: scaleY))
    }
    
    @inlinable
    @inline(__always)
    func scaled(x scaleX: CGFloat) -> CGRect
    {
        return .init(origin: origin.scaled(x: scaleX), size: size.scaled(x: scaleX))
    }
    
    @inlinable
    @inline(__always)
    func scaled(y scaleY: CGFloat) -> CGRect
    {
        return .init(origin: origin.scaled(y: scaleY), size: size.scaled(y: scaleY))
    }
    
    @inlinable
    @inline(__always)
    func scaled(_ scale: CGFloat) -> CGRect
    {
        return self * scale
    }
    
    /// Computes CGRect that acts as a Bounding Box for current and provided rectangles.
    /// See: ``union(_:)``
    @inlinable
    func union(_ rects: [CGRect]) -> CGRect
    {
        return CoreGraphicsExtension.union([self]+rects)
    }
}

extension CGRect: BinaryRepresentable {}
