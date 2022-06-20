//
//  UIKit.swift
//  
//
//  Created by Maksym Kulyk on 20.06.2022.
//

import UIKit

// MARK: - UIColor
public extension UIColor
{
    @inlinable
    convenience init(hex: UInt32, alpha: CGFloat = 1)
    {
        let r = CGFloat((hex & 0x00FF_0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x0000_FF00) >> 8) / 255.0
        let b = CGFloat((hex & 0x0000_00FF) >> 0) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - UIScreen
public extension UIScreen
{
    @MainActor
    @inlinable static var width: CGFloat
    {
        return UIScreen.main.bounds.size.width
    }
    
    @MainActor
    @inlinable static var height: CGFloat
    {
        return UIScreen.main.bounds.size.height
    }
}
