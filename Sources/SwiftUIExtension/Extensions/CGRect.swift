//
//  CGRect.swift
//  
//
//  Created by zeewanderer on 21.05.2024.
//

import SwiftUI
import CoreGraphics
import CoreGraphicsExtension

public extension CGRect
{
    @inlinable
    @inline(__always)
    func scaled(by scale: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = self.width * scale
        let newHeight = self.height * scale
        let newX = self.minX + anchor.x * (self.width - newWidth)
        let newY = self.minY + anchor.y * (self.height - newHeight)
        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
    
    @inlinable
    @inline(__always)
    func scaleResize(x scaleX: CGFloat, y scaleY: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = self.width * scaleX
        let newHeight = self.height * scaleY
        let newX = self.minX + anchor.x * (self.width - newWidth)
        let newY = self.minY + anchor.y * (self.height - newHeight)
        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
    
    @inlinable
    @inline(__always)
    func scaleResize(x scaleX: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = self.width * scaleX
        let newX = self.minX + anchor.x * (self.width - newWidth)
        return CGRect(x: newX, y: self.origin.y, width: newWidth, height: self.height)
    }
    
    @inlinable
    @inline(__always)
    func scaleResize(y scaleY: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newHeight = self.height * scaleY
        let newY = self.minY + anchor.y * (self.height - newHeight)
        return CGRect(x: self.origin.x, y: newY, width: self.width, height: newHeight)
    }
    
    @inlinable
    @inline(__always)
    func resize(width: CGFloat, height: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = width
        let newHeight = height
        let newX = self.minX + anchor.x * (self.width - newWidth)
        let newY = self.minY + anchor.y * (self.height - newHeight)
        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
    
    @inlinable
    @inline(__always)
    func resize(width: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = width
        let newX = self.minX + anchor.x * (self.width - newWidth)
        return CGRect(x: newX, y: self.origin.y, width: newWidth, height: self.height)
    }
    
    @inlinable
    @inline(__always)
    func resize(height: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newHeight = height
        let newY = self.minY + anchor.y * (self.height - newHeight)
        return CGRect(x: self.origin.x, y: newY, width: self.width, height: newHeight)
    }
}
