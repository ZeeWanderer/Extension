//
//  Basic.swift
//  Extension
//
//  Created by Maksym Kulyk on 9/16/20.
//  Copyright © 2020 max. All rights reserved.
//

import CoreGraphics
import FoundationExtension
import SwiftUI

public extension CGPoint
{
    @inline(__always)
    func translateBy(dx:CGFloat, dy:CGFloat) -> CGPoint
    {
        return CGPoint(x:self.x + dx, y:self.y + dy)
    }
    
    @inline(__always)
    func translate(by point: CGPoint) -> CGPoint
    {
        return CGPoint(x:self.x + point.x, y:self.y + point.y)
    }
    
    @inline(__always)
    func translate(by size: CGSize) -> CGPoint
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
}

public extension CGSize
{
    @inlinable
    var square: CGFloat
    {
        return self.height * self.width
    }
    
    @inlinable
    var center: CGPoint
    {
        return CGPoint(x: self.width/2.0, y: self.width/2.0)
    }
}

public extension CGRect
{
    @inlinable
    var center: CGPoint
    {
        return self.origin.translateBy(dx: self.width/2.0, dy: self.height/2.0)
    }
}
