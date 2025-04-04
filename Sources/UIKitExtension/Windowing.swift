//
//  Windowing.swift
//  
//
//  Created by zeewanderer on 31.10.2021.
//

#if canImport(UIKit)
import UIKit

// MARK: - UIApplication
public extension UIApplication
{
    /// Replacement for deprecated `UIApplication.keyWindow`
    /// - Returns: First key window managed by one of the `connectedScenes`
    /// ---
    /// [UIApplication.keyWindow](https://developer.apple.com/documentation/uikit/uiapplication/1622924-keywindow)
    @inlinable var keySceneWindow: UIWindow?
    {
        connectedScenes
            .compactMap { scene in
                scene as? UIWindowScene
            }
            .flatMap { windowScene in
                windowScene.windows
            }
            .first { window in
                window.isKeyWindow
            }
    }
}

// MARK: - UIViewController
public extension UIViewController
{
    @inlinable
    static func topMostViewController() -> UIViewController?
    {
        let keyWindow = UIApplication.shared.keySceneWindow
        return keyWindow?.rootViewController?.topMostViewController()
    }
    
    @inlinable
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
#endif
