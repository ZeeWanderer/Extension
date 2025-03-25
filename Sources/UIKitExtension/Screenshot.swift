//
//  Screenshot.swift
//  Extension
//
//  Created by zeewanderer on 8/26/20.
//  Copyright © 2020 max. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public extension UIView 
{
    @inlinable
    var screenShot: UIImage 
    {
        return self.layer.screenShot
    }
    
    @inlinable
    func screenShot(afterScreenUpdates: Bool) -> UIImage 
    {
        if !self.responds(to: #selector(drawHierarchy(in:afterScreenUpdates:))) 
        {
            return self.screenShot
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let screenshot = renderer.image
        {
            context in
            self.drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
        }
        return screenshot
    }
}

public extension UIApplication
{
    @inlinable
    var screenShot: UIImage?
    {
        return UIApplication.shared.keySceneWindow?.layer.screenShot
    }
}

public extension CALayer
{
    @inlinable
    var screenShot: UIImage
    {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        
        let screenshot = renderer.image
        {
            context in
            render(in: context.cgContext)
        }
        
        return screenshot
    }
}
#endif
