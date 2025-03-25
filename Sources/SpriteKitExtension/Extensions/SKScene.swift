//
//  Screenshot.swift
//  
//
//  Created by zeewanderer on 09.03.2022.
//

#if canImport(UIKit)
import UIKitExtension
import SpriteKit

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
        guard let keyWindow = UIApplication.shared.keySceneWindow
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
#endif
