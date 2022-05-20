//
//  Keyboard.swift
//  
//
//  Created by Maksym Kulyk on 11.04.2022.
//

import SwiftUI

/// Helper class that listens to keyboard notifications and provides observable keyboard height and a number of helper functions
/// - Note: Does not use `withAnimation`, so animation needs to be set by end user via `animation`.
public final class KeyboardHeightHelper: ObservableObject
{
    @Published public var keyboardHeight: CGFloat = 0
    
    @usableFromInline internal var duration: CGFloat = 0.25
    @usableFromInline internal var curve: UIView.AnimationCurve = .easeOut
    
    @inlinable
    public var isKeyboardActive: Bool
    {
        keyboardHeight != 0
    }
    
    /// Sends action to hide keyboard if it is not hidden
    /// - Returns: Whether the keyboard will be hidden.
    @inlinable
    @discardableResult public func endTextEditing() -> Bool
    {
        if isKeyboardActive
        {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
        
        return isKeyboardActive
    }
    
    /// Provides `Animation` value to match keyboard animation
    @inlinable
    public var animation: Animation
    {
        switch curve
        {
        case .linear:
            return .linear(duration: duration)
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .easeInOut:
            return .easeInOut(duration: duration)
        @unknown default:
            return .easeOut(duration: duration)
        }
    }
    
    internal func listenForKeyboardNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard_appear(_:)), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard_hide(_:)), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc internal func keyboard_appear(_ notification: Notification)
    {
        guard let userInfo = notification.userInfo,
              let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
              let curve_raw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber,
              let curve = UIView.AnimationCurve(rawValue: Int(truncating: curve_raw))
        else
        {
            return
        }
        
        self.curve = curve
        self.duration = CGFloat(truncating: duration)
        
        self.keyboardHeight = keyboardRect.height
    }
    
    @objc internal func keyboard_hide(_ notification: Notification)
    {
        self.keyboardHeight = 0
    }
    
    public init()
    {
        self.listenForKeyboardNotifications()
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - View
public extension View
{
    @inlinable
    func endTextEditing()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
