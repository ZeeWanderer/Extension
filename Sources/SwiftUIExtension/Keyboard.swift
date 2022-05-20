//
//  Keyboard.swift
//  
//
//  Created by Maksym Kulyk on 11.04.2022.
//

import SwiftUI

/// Helper class that listens to keyboard notification and provides observable keyboard height and a number of helper functions
/// - Note: Does not use `withAnimation`, so animation needs to be set by end user via `animation`.
public final class KeyboardHeightHelper: ObservableObject
{
    @Published public var keyboardHeight: CGFloat = 0
    
    @inlinable
    public var isKeyboardActive: Bool
    {
        keyboardHeight != 0
    }
    
    @inlinable
    public func endTextEditing()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
    
    internal func listenForKeyboardNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard_appear(_:)), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard_hide(_:)), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc internal func keyboard_appear(_ notification: Notification)
    {
        guard let userInfo = notification.userInfo,
              let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else
        {
            return
        }
        
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
