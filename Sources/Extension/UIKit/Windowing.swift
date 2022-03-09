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
    var keyWindow: UIWindow?
    {
        connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .flatMap {
                $0.windows
            }
            .first {
                $0.isKeyWindow
            }
    }
}

// -MARK: UIViewController EXTENSION

public extension UIViewController
{
    @inlinable
    static func topMostViewController() -> UIViewController?
    {
        let keyWindow = UIApplication.shared.keyWindow
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
