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
}
