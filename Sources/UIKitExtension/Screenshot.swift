//
//  Screenshot.swift
//  Extension
//
//  Created by Maksym Kulyk on 8/26/20.
//  Copyright © 2020 max. All rights reserved.
//

import UIKit

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
