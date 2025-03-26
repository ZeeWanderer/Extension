//
//  CGSize+FloatingPoint2D.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

extension CGSize: FloatingPoint2D
{
    public typealias Magnitude = CGFloat
    
    @inlinable
    @inline(__always)
    public init(xMagnitude: Magnitude, yMagnitude: Magnitude)
    {
        self.init(width: xMagnitude, height: yMagnitude)
    }
    
    @inlinable
    @inline(__always)
    public var xMagnitude: CGFloat {
        get {
            self.width
        }
        set {
            self.width = newValue
        }
    }
    
    @inlinable
    @inline(__always)
    public var yMagnitude: CGFloat {
        get {
            self.height
        }
        set {
            self.height = newValue
        }
    }
}
