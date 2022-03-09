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
