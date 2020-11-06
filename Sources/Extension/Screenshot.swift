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

    var screenShot: UIImage?
    {
        return keyWindow?.layer.screenShot
    }
}

public extension CALayer
{

    var screenShot: UIImage?
    {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(frame.size, false, scale)
        if let context = UIGraphicsGetCurrentContext()
        {
            render(in: context)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return screenshot
        }
        return nil
    }
}
