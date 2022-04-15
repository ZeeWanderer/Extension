//
//  Windowing.swift
//  
//
//  Created by Maksym Kulyk on 31.10.2021.
//

import UIKit

public extension UIApplication
{
    /// Replacement for deprecated `UIApplication.keyWindow`
    /// - Returns: First key window managed by one of the `connectedScenes`
    /// ---
    /// [UIApplication.keyWindow](https://developer.apple.com/documentation/uikit/uiapplication/1622924-keywindow)
    @inlinable var keySceneWindow: UIWindow?
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
    
    @available(*, deprecated, renamed: "keySceneWindow")
    @inlinable var keyWindow_: UIWindow?
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
        let keyWindow = UIApplication.shared.keySceneWindow
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
