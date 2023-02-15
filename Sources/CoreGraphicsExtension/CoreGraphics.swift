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
    func lerped(min: CGPoint, max: CGPoint) -> CGPoint
    {
        return lerp(self, min: min, max: max)
    }
    
    /// inverse linear intepolate a point between `min` and `max` with `self` as `parameter` (t).
    /// See:  ``ilerp(_:min:max:)-59add``
    @inlinable
    @inline(__always)
    func ilerped(min: CGPoint, max: CGPoint) -> CGPoint
    {
        return ilerp(self, min: min, max: max)
    }
}

extension CGFloat: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.size)
    }
}

// MARK: - CGVector
public extension CGVector
{
    @inlinable
    init(_ point: CGPoint)
    {
        self.init(dx: point.x, dy: point.y)
    }
    
    @inlinable
    @inline(__always)
    init(_ size: CGSize)
    {
        self.init(dx: size.width, dy: size.height)
    }
    
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
    func clamped(dx range: ClosedRange<CGFloat>) -> CGVector
    {
        return clamp(self, dx: range)
    }
    
    /// See ``clamp(_:dy:)``
    @inlinable
    @inline(__always)
    func clamped(dy range: ClosedRange<CGFloat>) -> CGVector
    {
        return clamp(self, dy: range)
    }
    
    /// See ``clamp(_:dx:dy:)``
    @inlinable
    @inline(__always)
    func clamped(dx rangeDx: ClosedRange<CGFloat>, dy rangeDy: ClosedRange<CGFloat>) -> CGVector
    {
        return clamp(self, dx: rangeDx, dy: rangeDy)
    }
    
    /// See  ``clamp(_:to:)``
    @inlinable
    @inline(__always)
    func clamped(to range: ClosedRange<CGFloat>) -> CGVector
    {
        return clamp(self, to: range)
    }
}

extension CGVector: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return .init(bytes: &selfMutable, count: MemoryLayout<Self>.size)
    }
}

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
    
    /// linear intepolate a point between `min` and `max` with `self` as `parameter`.
    /// See:  ``lerp(_:min:max:)-z0dd``
    @inlinable
    @inline(__always)
    func lerped(min: CGPoint, max: CGPoint) -> CGPoint
    {
        return lerp(self, min: min, max: max)
    }
    
    /// linear intepolate a point between `min` and `max` for `parameter`  with `self` as `min`.
    /// See:  ``lerp(_:min:max:)-z0dd``
    @inlinable
    @inline(__always)
    func lerped(_ parameter: CGPoint, max: CGPoint) -> CGPoint
    {
        return lerp(parameter, min: self, max: max)
    }
    
    /// linear intepolate a point between `min` and `max` for `parameter`  with `self` as `max`.
    /// See:  ``lerp(_:min:max:)-z0dd``
    @inlinable
    @inline(__always)
    func lerped(_ parameter: CGPoint, min: CGPoint) -> CGPoint
    {
        return lerp(parameter, min: min, max: self)
    }
    
    /// inverse linear intepolate a point between `min` and `max` with `self` as `parameter`.
    /// See:  ``ilerp(_:min:max:)-24jcs``
    @inlinable
    @inline(__always)
    func ilerped(min: CGPoint, max: CGPoint) -> CGPoint
    {
        return ilerp(self, min: min, max: max)
    }
    
    /// inverse linear intepolate a point between `min` and `max` for `parameter`  with `self` as `min`.
    /// See:  ``ilerp(_:min:max:)-24jcs``
    @inlinable
    @inline(__always)
    func ilerped(_ parameter: CGPoint, max: CGPoint) -> CGPoint
    {
        return ilerp(parameter, min: self, max: max)
    }
    
    /// inverse linear intepolate a point between `min` and `max` for `parameter`  with `self` as `max`.
    /// See:  ``ilerp(_:min:max:)-24jcs``
    @inlinable
    @inline(__always)
    func ilerped(_ parameter: CGPoint, min: CGPoint) -> CGPoint
    {
        return ilerp(parameter, min: min, max: self)
    }
    
    /// See ``clamp(_:x:)``
    @inlinable
    @inline(__always)
    func clamped(x range: ClosedRange<CGFloat>) -> CGPoint
    {
        return clamp(self, x: range)
    }
    
    /// See ``clamp(_:y:)``
    @inlinable
    @inline(__always)
    func clamped(y range: ClosedRange<CGFloat>) -> CGPoint
    {
        return clamp(self, y: range)
    }
    
    /// See ``clamp(_:x:y:)``
    @inlinable
    @inline(__always)
    func clamped(x rangeX: ClosedRange<CGFloat>, y rangeY: ClosedRange<CGFloat>) -> CGPoint
    {
        return clamp(self, x: rangeX, y: rangeY)
    }
    
    /// See  ``clamp(_:to:)``
    @inlinable
    @inline(__always)
    func clamped(to range: ClosedRange<CGFloat>) -> CGPoint
    {
        return clamp(self, to: range)
    }
}

extension CGPoint: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return .init(bytes: &selfMutable, count: MemoryLayout<Self>.size)
    }
}

// MARK: - CGSize
public extension CGSize
{
    @inlinable
    @inline(__always)
    init(_ point: CGPoint)
    {
        self.init(width: point.x, height: point.y)
    }
    
    @inlinable
    @inline(__always)
    init(side: CGFloat)
    {
        self.init(width: side, height: side)
    }
    
    @inlinable
    @inline(__always)
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize
    {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
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
    func clamped(width range: ClosedRange<CGFloat>) -> CGSize
    {
        return clamp(self, width: range)
    }
    
    /// See ``clamp(_:height:)``
    @inlinable
    @inline(__always)
    func clamped(height range: ClosedRange<CGFloat>) -> CGSize
    {
        return clamp(self, height: range)
    }
    
    /// See ``clamp(_:width:height:)``
    @inlinable
    @inline(__always)
    func clamped(width rangeWidth: ClosedRange<CGFloat>, height rangeHeight: ClosedRange<CGFloat>) -> CGSize
    {
        return clamp(self, width: rangeWidth, height: rangeHeight)
    }
    
    /// See  ``clamp(_:to:)``
    @inlinable
    @inline(__always)
    func clamped(to range: ClosedRange<CGFloat>) -> CGSize
    {
        return clamp(self, to: range)
    }
}

extension CGSize: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return .init(bytes: &selfMutable, count: MemoryLayout<Self>.size)
    }
}

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
    
    /// Computes CGRect that acts as a Bounding Box for current and provided rectangles.
    /// See: ``union(_:)``
    @inlinable
    func union(_ rects: [CGRect]) -> CGRect
    {
        return CoreGraphicsExtension.union([self]+rects)
    }
}

extension CGRect: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.size)
    }
}
