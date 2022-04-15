//
//  Basic.swift
//  Extension
//
//  Created by Maksym Kulyk on 9/16/20.
//  Copyright © 2020 max. All rights reserved.
//

import CoreGraphics
import FoundationExtension

// MARK: - CGPoint
public extension CGPoint
{
    /// Translate CGPoint by a given ammount
    @inline(__always)
    func translatedBy(dx:CGFloat, dy:CGFloat) -> CGPoint
    {
        return CGPoint(x:self.x + dx, y:self.y + dy)
    }
    
    /// Translate CGPoint by a vector defined as ((0,0), point)
    @inline(__always)
    func translated(by point: CGPoint) -> CGPoint
    {
        return CGPoint(x:self.x + point.x, y:self.y + point.y)
    }
    
    /// Translate CGPoint by a vector defined as ((0,0), size)
    @inline(__always)
    func translated(by size: CGSize) -> CGPoint
    {
        return CGPoint(x:self.x + size.width, y:self.y + size.height)
    }
    
    @inline(__always)
    static func * (_ lhs: CGPoint, _ rhs: CGFloat) -> CGPoint
    {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    @inline(__always)
    static func / (_ lhs: CGPoint, _ rhs: CGFloat) -> CGPoint
    {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    @inline(__always)
    static func + (lhs:CGPoint, rhs: CGFloat) -> CGPoint
    {
        return CGPoint(x: lhs.x + rhs, y: lhs.y + rhs)
    }
    
    @inline(__always)
    static func - (lhs:CGPoint, rhs: CGFloat) -> CGPoint
    {
        return CGPoint(x: lhs.x - rhs, y: lhs.y - rhs)
    }
    
    @inline(__always)
    static func + (lhs:CGPoint, rhs: CGPoint) -> CGPoint
    {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    @inline(__always)
    static func - (lhs:CGPoint, rhs: CGPoint) -> CGPoint
    {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    // MARK: DEPRECATED
    @available(*, deprecated, renamed: "translatedBy(dx:dy:)")
    @inline(__always)
    func translateBy(dx:CGFloat, dy:CGFloat) -> CGPoint
    {
        return translatedBy(dx: dx, dy: dy)
    }
    
    @available(*, deprecated, renamed: "translated(by:)")
    @inline(__always)
    func translate(by point: CGPoint) -> CGPoint
    {
        return translated(by: point)
    }
    
    @available(*, deprecated, renamed: "translated(by:)")
    @inline(__always)
    func translate(by size: CGSize) -> CGPoint
    {
        return translated(by: size)
    }
}

// MARK: - CGSize
public extension CGSize
{
    @inline(__always)
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize
    {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    /// `width * height`
    @inline(__always)
    var square: CGFloat
    {
        return self.height * self.width
    }
    
    /// Center point of the rectange area defined by `CGSize`
    @inline(__always)
    var center: CGPoint
    {
        return CGPoint(x: self.width/2.0, y: self.width/2.0)
    }
}

// MARK: - CGSize
public extension CGRect
{
    /// Translate CGRect by a given ammount
    @inline(__always)
    func translatedBy(dx:CGFloat, dy:CGFloat) -> CGRect
    {
        return CGRect(origin: self.origin.translatedBy(dx: dx, dy: dy), size: size)
    }
    
    /// Translate CGRect by a vector defined as ((0,0), point)
    @inline(__always)
    func translated(by point: CGPoint) -> CGRect
    {
        return CGRect(origin: self.origin.translated(by: point), size: size)
    }
    
    /// Translate CGRect by a vector defined as ((0,0), size)
    @inline(__always)
    func translated(by size: CGSize) -> CGRect
    {
        return CGRect(origin: self.origin.translated(by: size), size: size)
    }
    
    // Includes origin into scaling because CGSize describes
    // an are without position, but CGRect describes an area
    // with position.
    @inline(__always)
    static func * (lhs: CGRect, rhs: CGFloat) -> CGRect
    {
        return CGRect(origin: lhs.origin * rhs, size: lhs.size * rhs)
    }
    
    /// `width * height`
    @inline(__always)
    var square: CGFloat
    {
        return self.size.square
    }
    
    /// Center point of the `CGRect`
    /// - Note: With respect to origin
    @inline(__always)
    var center: CGPoint
    {
        return self.origin.translatedBy(dx: self.width/2.0, dy: self.height/2.0)
    }
    
    // MARK: DEPRECATED
    @available(*, deprecated, renamed: "translatedBy(dx:dy:)")
    @inline(__always)
    func translateBy(dx:CGFloat, dy:CGFloat) -> CGRect
    {
        return CGRect(origin: self.origin.translatedBy(dx: dx, dy: dy), size: size)
    }
    
    @available(*, deprecated, renamed: "translated(by:)")
    @inline(__always)
    func translate(by point: CGPoint) -> CGRect
    {
        return CGRect(origin: self.origin.translated(by: point), size: size)
    }
    
    @available(*, deprecated, renamed: "translated(by:)")
    @inline(__always)
    func translate(by size: CGSize) -> CGRect
    {
        return CGRect(origin: self.origin.translated(by: size), size: size)
    }
}
