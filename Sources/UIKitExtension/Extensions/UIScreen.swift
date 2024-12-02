//
//  UIScreen.swift
//
//
//  Created by zee wanderer on 02.08.2024.
//

#if canImport(UIKit)
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
#endif
