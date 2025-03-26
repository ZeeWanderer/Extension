//
//  CGSize.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

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
    
    @inlinable
    @inline(__always)
    var diagonal: CGFloat
    {
        // Opt for squares
        if self.width == self.height { return self.width * CGFloat.root(2.0, 2) }
        
        // Universal path
        return CGFloat.root(CGFloat.pow(self.width, 2) + CGFloat.pow(self.height, 2), 2)
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
