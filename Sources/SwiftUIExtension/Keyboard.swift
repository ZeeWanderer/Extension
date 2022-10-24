//
//  Keyboard.swift
//  
//
//  Created by Maksym Kulyk on 11.04.2022.
//

import SwiftUI

/// Helper class that listens to keyboard notifications and provides observable keyboard height and a number of helper functions
/// - Note: Does not use `withAnimation`, so animation needs to be set by end user via `animation`.
@MainActor public final class KeyboardHeightHelper: ObservableObject
{
    @MainActor @Published public var keyboardHeight: CGFloat = 0
    
    @usableFromInline internal var duration: CGFloat = 0.25
    @usableFromInline internal var curve: UIView.AnimationCurve = .easeOut
    @usableFromInline internal var keyboardWillShowNotificationTask: Task<Void,Never>? = nil
    @usableFromInline internal var keyboardWillHideNotificationTask: Task<Void,Never>? = nil
    
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
            return UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                   to: nil, from: nil, for: nil)
        }
        
        return false
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
    
    @usableFromInline @MainActor
    internal func set_keyboardHeight(_ value: CGFloat) async
    {
        self.keyboardHeight = value
    }
    
    @usableFromInline
    internal func listenForKeyboardNotifications()
    {
        keyboardWillShowNotificationTask = Task
        {
            [weak self] in
            for await notification in NotificationCenter.default.notifications(named: UIResponder.keyboardWillShowNotification)
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
                
                self?.curve = curve
                self?.duration = CGFloat(truncating: duration)
                
                await self?.set_keyboardHeight(keyboardRect.height)
            }
        }
        
        keyboardWillHideNotificationTask = Task
        {
            [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillHideNotification)
            {
                await self?.set_keyboardHeight(0)
            }
        }
    }
    
    public init()
    {
        self.listenForKeyboardNotifications()
    }
    
    @inlinable
    deinit
    {
        self.keyboardWillShowNotificationTask?.cancel()
        self.keyboardWillHideNotificationTask?.cancel()
    }
}

// MARK: - View
public extension View
{
    @MainActor @inlinable
    @discardableResult func endTextEditing() -> Bool
    {
        return UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                               to: nil, from: nil, for: nil)
    }
}
