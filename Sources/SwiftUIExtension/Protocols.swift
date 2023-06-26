//
//  File.swift
//  
//
//  Created by Maksym Kulyk on 26.06.2023.
//

import SwiftUI
import CoreGraphicsExtension

// MARK: - FloatingPoint2D

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
