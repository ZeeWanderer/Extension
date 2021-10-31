//
//  Windowing.swift
//  
//
//  Created by Maksym Kulyk on 31.10.2021.
//

import UIKit

public extension UIApplication
{
    @inlinable
    static func get_keyWindow() -> UIWindow?
    {
        return UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    }
    
}

// -MARK: UIViewController EXTENSION

public extension UIViewController
{
    @inlinable
    static func topMostViewController() -> UIViewController?
    {
        let keyWindow = UIApplication.get_keyWindow()
        return keyWindow?.rootViewController?.topMostViewController()
    }
    
    func topMostViewController() -> UIViewController?
    {
        if let presentedViewController = self.presentedViewController
        {
            return presentedViewController.topMostViewController()
        }
        else
            if let navigationController = self as? UINavigationController
        {
                return navigationController.topViewController?.topMostViewController()
            }
        else
            if let tabBarController = self as? UITabBarController
        {
                if let selectedViewController = tabBarController.selectedViewController
                {
                    return selectedViewController.topMostViewController()
                }
                return tabBarController.topMostViewController()
            }
        else
        {
            return self
        }
    }
}
