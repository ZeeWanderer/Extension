//
//  File.swift
//  
//
//  Created by Maksym Kulyk on 13.03.2023.
//

import SwiftUI
import CoreGraphics
import CoreGraphicsExtension

// MARK: - CGPoint
public extension CGPoint
{
    @inlinable
    @inline(__always)
    init(_ point: UnitPoint)
    {
        self.init(x: point.x, y: point.y)
    }
    
    /// Center Anchor bridged from `UnitPoint.center`
    static let center: CGPoint = UnitPoint.center.cgPoint
    static let leading: CGPoint = UnitPoint.leading.cgPoint
    static let trailing: CGPoint = UnitPoint.trailing.cgPoint
    static let top: CGPoint = UnitPoint.top.cgPoint
    static let bottom: CGPoint = UnitPoint.bottom.cgPoint
    static let topLeading: CGPoint = UnitPoint.topLeading.cgPoint
    static let bottomLeading: CGPoint = UnitPoint.bottomLeading.cgPoint
    static let topTrailing: CGPoint = UnitPoint.topTrailing.cgPoint
    static let bottomTrailing: CGPoint = UnitPoint.bottomTrailing.cgPoint
}

public extension CGRect
{
    @inlinable
    @inline(__always)
    func scaled(by scale: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = self.width * scale
        let newHeight = self.height * scale
        let newX = self.midX - anchor.x * newWidth
        let newY = self.midY - anchor.y * newHeight
        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
    
    @inlinable
    @inline(__always)
    func scaleResize(x scaleX: CGFloat, y scaleY: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = self.width * scaleX
        let newHeight = self.height * scaleY
        let newX = self.midX - anchor.x * newWidth
        let newY = self.midY - anchor.y * newHeight
        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
    
    @inlinable
    @inline(__always)
    func scaleResize(x scaleX: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = self.width * scaleX
        let newX = self.midX - anchor.x * newWidth
        return CGRect(x: newX, y: self.origin.y, width: newWidth, height: self.height)
    }
    
    @inlinable
    @inline(__always)
    func scaleResize(y scaleY: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newHeight = self.height * scaleY
        let newY = self.midY - anchor.y * newHeight
        return CGRect(x: self.origin.x, y: newY, width: self.width, height: newHeight)
    }
    
    @inlinable
    @inline(__always)
    func resize(width: CGFloat, height: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = width
        let newHeight = height
        let newX = self.midX - anchor.x * newWidth
        let newY = self.midY - anchor.y * newHeight
        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
    
    @inlinable
    @inline(__always)
    func resize(width: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newWidth = width
        let newX = self.midX - anchor.x * newWidth
        return CGRect(x: newX, y: self.origin.y, width: newWidth, height: self.height)
    }
    
    @inlinable
    @inline(__always)
    func resize(height: CGFloat, anchor: UnitPoint = .center) -> CGRect {
        let newHeight = height
        let newY = self.midY - anchor.y * newHeight
        return CGRect(x: self.origin.x, y: newY, width: self.width, height: newHeight)
    }
}
