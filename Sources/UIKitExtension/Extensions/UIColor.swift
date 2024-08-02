//
//  UIColor.swift
//
//
//  Created by zee wanderer on 02.08.2024.
//

import UIKit

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
