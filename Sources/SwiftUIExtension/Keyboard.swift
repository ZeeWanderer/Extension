//
//  Keyboard.swift
//  
//
//  Created by Maksym Kulyk on 11.04.2022.
//

import SwiftUI

public class KeyboardHeightHelper: ObservableObject
{
    @Published public var keyboardHeight: CGFloat = 0
    
    @inlinable
    public var isKeyboardActive: Bool
    {
        keyboardHeight != 0
    }
    
    internal func listenForKeyboardNotifications() {
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
        
        withAnimation
        {
            self.keyboardHeight = keyboardRect.height
        }
    }
    
    @objc internal func keyboard_hide(_ notification: Notification)
    {
        withAnimation
        {
            self.keyboardHeight = 0
        }
    }
    
    public init()
    {
        self.listenForKeyboardNotifications()
    }
}
