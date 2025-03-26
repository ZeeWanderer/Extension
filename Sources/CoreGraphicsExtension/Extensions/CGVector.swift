//
//  CGVector.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

public extension CGVector
{
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
