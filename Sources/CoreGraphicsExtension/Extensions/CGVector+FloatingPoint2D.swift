//
//  CGVector+FloatingPoint2D.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

extension CGVector: FloatingPoint2D
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
    public var xMagnitude: CGFloat {
        get {
            self.dx
        }
        set {
            self.dx = newValue
        }
    }
    
    @inlinable
    @inline(__always)
    public var yMagnitude: CGFloat {
        get {
            self.dy
        }
        set {
            self.dy = newValue
        }
    }
}
