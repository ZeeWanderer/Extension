//
//  Color.swift
//  Extension
//
//  Created by zee wanderer on 09.10.2024.
//


import SwiftUI

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
    
    /// - Parameter hex: a hex literal color representation, 4 bytes
    /// in standard # format or any recognizable hex format
    @inlinable
    init?(_ colorSpace: Color.RGBColorSpace = .sRGB, hex: String)
    {
        let r, g, b, a: CGFloat
        
        let offsetBy = hex.hasPrefix("#") ? 1 : (hex.hasPrefix("0x") || hex.hasPrefix("0X") ? 2 : 0)
        let start = hex.index(hex.startIndex, offsetBy: offsetBy)
        let hexColor = String(hex[start...])
        
        if hexColor.count == 8
        {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber)
            {
                r = CGFloat((hexNumber & 0xFF_00_00_00) >> 24) / 255
                g = CGFloat((hexNumber & 0x00_FF_00_00) >> 16) / 255
                b = CGFloat((hexNumber & 0x00_00_FF_00) >> 8) / 255
                a = CGFloat((hexNumber & 0x00_00_00_FF) >> 0) / 255
                
                self.init(colorSpace, red: r, green: g, blue: b, opacity: a)
                return
            }
        }
        
        return nil
    }
    
    /// - Parameter hex: a hex literal color representation, 3 or 4 bytes
    /// in standard # format or any recognizable hex format.
    /// - Parameter opacity: color alpha
    /// - Important: If 4 bytes are provided, `alpha` parameter overrides alpha from `hex`
    @inlinable
    init?(_ colorSpace: Color.RGBColorSpace = .sRGB, hex: String, opacity: CGFloat)
    {
        let r, g, b: CGFloat
        
        let offsetBy = hex.hasPrefix("#") ? 1 : (hex.hasPrefix("0x") || hex.hasPrefix("0X") ? 2 : 0)
        let start = hex.index(hex.startIndex, offsetBy: offsetBy)
        let hexColor = String(hex[start...])
        
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        
        guard scanner.scanHexInt64(&hexNumber) else { return nil }
        
        if hexColor.count == 6
        {
            r = CGFloat((hexNumber & 0x00_FF_00_00) >> 16) / 255.0
            g = CGFloat((hexNumber & 0x00_00_FF_00) >> 8) / 255.0
            b = CGFloat((hexNumber & 0x00_00_00_FF) >> 0) / 255.0
            
            self.init(colorSpace, red: r, green: g, blue: b, opacity: opacity)
            return
        }
        else if hexColor.count == 8
        {
            r = CGFloat((hexNumber & 0xFF_00_00_00) >> 24) / 255
            g = CGFloat((hexNumber & 0x00_FF_00_00) >> 16) / 255
            b = CGFloat((hexNumber & 0x00_00_FF_00) >> 8) / 255
            
            self.init(colorSpace, red: r, green: g, blue: b, opacity: opacity)
            return
        }
        
        return nil
    }
}