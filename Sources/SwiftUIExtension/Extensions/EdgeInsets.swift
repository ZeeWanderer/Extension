//
//  EdgeInsets.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//

import SwiftUI
import CoreGraphicsExtension

public extension EdgeInsets
{
    @inlinable
    static var zero: EdgeInsets
    {
        .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    /// Returns default padding if inset is 0
    @inlinable
    var trailingDefaultPadding: CGFloat?
    {
        trailing == 0 ? nil : 0
    }
    
    /// Returns default padding if inset is 0
    @inlinable
    var leadingDefaultPadding: CGFloat?
    {
        leading == 0 ? nil : 0
    }
    
    /// Returns default padding if inset is 0
    @inlinable
    var topDefaultPadding: CGFloat?
    {
        top == 0 ? nil : 0
    }
    
    /// Returns default padding if inset is 0
    @inlinable
    var bottomDefaultPadding: CGFloat?
    {
        bottom == 0 ? nil : 0
    }
    
    @inlinable
    @inline(__always)
    func scaled(x scaleX: CGFloat, y scaleY: CGFloat) -> EdgeInsets
    {
        .init(top: top * scaleY, leading: leading * scaleX, bottom: bottom * scaleY, trailing: trailing * scaleX)
    }
    
    @inlinable
    @inline(__always)
    func scaled(x scaleX: CGFloat) -> EdgeInsets
    {
        .init(top: top, leading: leading * scaleX, bottom: bottom, trailing: trailing * scaleX)
    }
    
    @inlinable
    @inline(__always)
    func scaled(y scaleY: CGFloat) -> EdgeInsets
    {
        .init(top: top * scaleY, leading: leading, bottom: bottom * scaleY, trailing: trailing)
    }
    
    @inlinable
    @inline(__always)
    func scaled(_ scale: CGFloat) -> EdgeInsets
    {
        return self * scale
    }
    
    @inlinable
    @inline(__always)
    static func .* <T>(_ lhs: Self, _ rhs: T) -> Self where T: Numeric2D, T.Magnitude == CGFloat
    {
        return .init(top: lhs.top * rhs.yMagnitude, leading: lhs.leading * rhs.xMagnitude, bottom: lhs.bottom * rhs.yMagnitude, trailing: lhs.trailing * rhs.xMagnitude)
    }
    
    @inlinable
    func inset(for edge: Edge) -> CGFloat
    {
        switch edge {
        case .top:
            return self.top
        case .leading:
            return self.leading
        case .bottom:
            return self.bottom
        case .trailing:
            return self.trailing
        }
    }
    
    @inlinable
    func inset(for edge: Edge, or default: CGFloat) -> CGFloat
    {
        let inset_ = self.inset(for: edge)
        return inset_ == 0 ? `default` : inset_
    }
}
