//
//  Screenshot.swift
//  Extension
//
//  Created by Maksym Kulyk on 8/26/20.
//  Copyright © 2020 max. All rights reserved.
//

import UIKit
import SpriteKit

public extension UIApplication
{
    @inlinable
    var screenShot: UIImage?
    {
        return UIApplication.get_keyWindow()?.layer.screenShot
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

public extension SKScene
{
    /// Screenshot of the current scene
    @inlinable
    var screenShot: UIImage
    {
        let bounds = self.view!.bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        
        let screenshotImage = renderer.image
        {
            context in
            self.view!.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        
        return screenshotImage;
    }
    
    /// Composits SKscene on top of ViewController it resides in
    @inlinable
    var screenShot_composite: UIImage?
    {
        guard let keyWindow = UIApplication.get_keyWindow()
        else {return nil}
        guard let skview = self.view
        else {return nil}
        guard let local_superview = skview.superview
        else {return nil}
        
        let renderer = UIGraphicsImageRenderer(bounds: UIScreen.main.bounds)
        
        let globalPosition = local_superview.convert(skview.frame, to: nil)
        
        let screenshotImage = renderer.image
        {
            context in
            keyWindow.layer.render(in: context.cgContext)
            self.view!.drawHierarchy(in: globalPosition, afterScreenUpdates: true)
        }
        
        return screenshotImage;
    }
}
