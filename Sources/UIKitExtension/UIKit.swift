//
//  UIKit.swift
//  
//
//  Created by Maksym Kulyk on 20.06.2022.
//

import UIKit

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
