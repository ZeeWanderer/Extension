//
//  CGPoint+FloatingPoint2D.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

extension CGPoint: FloatingPoint2D
{
    public typealias Magnitude = CGFloat
    
    @inlinable
    @inline(__always)
    public init(xMagnitude: Magnitude, yMagnitude: Magnitude)
    {
        self.init(x: xMagnitude, y: yMagnitude)
    }
    
    @inlinable
    @inline(__always)
    public var xMagnitude: CGFloat {
        get {
            self.x
        }
        set {
            self.x = newValue
        }
    }
    
    @inlinable
    @inline(__always)
    public var yMagnitude: CGFloat {
        get {
            self.y
        }
        set {
            self.y = newValue
        }
    }
}
