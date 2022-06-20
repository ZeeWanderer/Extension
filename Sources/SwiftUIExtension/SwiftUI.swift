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
