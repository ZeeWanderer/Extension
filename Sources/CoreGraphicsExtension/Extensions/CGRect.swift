//
//  CGRect.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

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
        return .init(origin: self.origin.translatedBy(dx: dx, dy: dy), size: self.size)
    }
    
    /// Translate CGRect by a vector defined as ((0,0), point)
    @inlinable
    @inline(__always)
    func translated(by point: CGPoint) -> CGRect
    {
        return .init(origin: self.origin.translated(by: point), size: self.size)
    }
    
    /// Translate CGRect by a vector defined as ((0,0), size)
    @inlinable
    @inline(__always)
    func translated(by size: CGSize) -> CGRect
    {
        return .init(origin: self.origin.translated(by: size), size: self.size)
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
    
    @inlinable
    @inline(__always)
    static func .* <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == CGFloat
    {
        return .init(origin: lhs.origin .* rhs, size: lhs.size .* rhs)
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
        self.size.diagonal
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
