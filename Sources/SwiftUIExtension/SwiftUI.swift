//
//  SwiftUI.swift
//  
//
//  Created by Maksym Kulyk on 09.03.2022.
//

import SwiftUI

// MARK: - UIEdgeInsets
public extension UIEdgeInsets
{
    @inlinable
    var swiftUIInsets: EdgeInsets
    {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

// MARK: - EdgeInsets
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
}

// MARK: - Color
public extension Color
{
    @inlinable
    init(_ colorSpace: Color.RGBColorSpace = .sRGB, hex: UInt32, opacity: CGFloat = 1)
    {
        let r = Double((hex & 0x00FF_0000) >> 16) / 255.0
        let g = Double((hex & 0x0000_FF00) >> 8) / 255.0
        let b = Double((hex & 0x0000_00FF) >> 0) / 255.0
        self.init(colorSpace, red: r, green: g, blue: b, opacity: opacity)
    }
}
// MARK: - UnitPoint
public extension UnitPoint
{
    @inlinable
    @inline(__always)
    var cgPoint: CGPoint
    {
        return .init(x: self.x, y: self.y)
    }
}

// MARK: - Animation
public extension Animation
{
    @inlinable
    func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation
    {
        if expression
        {
            return self.repeatForever(autoreverses: autoreverses)
        }
        else
        {
            return self
        }
    }
}

// MARK: - Structs -



// MARK: - Shadow
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
}
