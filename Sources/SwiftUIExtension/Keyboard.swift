//
//  Keyboard.swift
//  
//
//  Created by Maksym Kulyk on 11.04.2022.
//

import SwiftUI

class KeyboardHeightHelper: ObservableObject
{
    @Published public var keyboardHeight: CGFloat = 0
    
    @inlinable
    public var isKeyboardActive: Bool
    {
        keyboardHeight != 0
    }
    
    private func listenForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard_appear(_:)), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboard_hide(_:)), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboard_appear(_ notification: Notification)
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
    
    @objc func keyboard_hide(_ notification: Notification)
    {
        withAnimation
        {
            self.keyboardHeight = 0
        }
    }
    
    init()
    {
        self.listenForKeyboardNotifications()
    }
}
