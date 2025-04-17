//
//  that.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//

import SwiftUI

/// A struct that describes SwiftUi shadow
public struct Shadow
{
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    @inlinable
    public init(color: Color = .init(.sRGBLinear, white: 0, opacity: 0.33), radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0)
    {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
    
    @inlinable
    public static func * (lhs: Self, rhs: CGFloat) -> Self
    {
        return Self(color: lhs.color, radius: lhs.radius * rhs, x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    @inlinable
    public static func * <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == CGFloat
    {
        let minScale = min(rhs.xMagnitude, rhs.yMagnitude)
        return Self(color: lhs.color, radius: lhs.radius * minScale, x: lhs.x * rhs.xMagnitude, y: lhs.y * rhs.yMagnitude)
    }
}
