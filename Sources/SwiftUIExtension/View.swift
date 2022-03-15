//
//  View.swift
//  
//
//  Created by Maksym Kulyk on 19.11.2021.
//

import SwiftUI

//MARK: - View
public extension View
{
    
    // MARK: Keyboard
    @inlinable
    func endTextEditing()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
    
    // MARK: Notifications
    @inlinable
    func onNotification(_ notificationName: Notification.Name, perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onReceive(NotificationCenter.default.publisher(for: notificationName), perform: action)
    }
    
    @inlinable
    func onDidEnterBackgroundNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.didEnterBackgroundNotification,
            perform: action
        )
    }
    
    @inlinable
    func onWillEnterForegroundNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.willEnterForegroundNotification,
            perform: action
        )
    }
    
    // MARK: Modifiers
    @inlinable
    func glow(radius: CGFloat = 5) -> some View
    {
        self
            .overlay(self.blur(radius: radius))
    }
    
    @inlinable
    func glow(color: Color = .yellow, radius: CGFloat = 5) -> some View
    {
        self
            .shadow(color: color, radius: radius / 2)
            .shadow(color: color, radius: radius / 2)
    }
    
    // MARK: Debug
    @inlinable
    func debugRect(color: Color = .red) -> some View
    {
#if DEBUG
        self.overlay(Rectangle().stroke(color))
#else
        return self
#endif
    }
    
    @inlinable
    func debugBorder(color: Color = .red) -> some View
    {
#if DEBUG
        self.border(color)
#else
        self
#endif
    }
}
