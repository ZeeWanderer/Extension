//
//  UnitPoint+FloatingPoint2D.swift
//
//
//  Created by Maksym Kulyk on 21.05.2024.
//

import SwiftUI
import CoreGraphicsExtension

extension UnitPoint: FloatingPoint2D
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
