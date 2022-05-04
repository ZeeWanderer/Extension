//
//  Environment.swift
//  
//
//  Created by Maksym Kulyk on 09.03.2022.
//

@_exported import UIKitExtension
import SwiftUI

public struct SafeAreaInsetsKey: EnvironmentKey
{
    public static var defaultValue: EdgeInsets
    {
        UIApplication.shared.keySceneWindow?.safeAreaInsets.swiftUIInsets ?? EdgeInsets()
    }
}

public extension EnvironmentValues
{
    /// The current SafeArea EdgeInsets of the scene
    ///
    /// This value is set to provide observable EdgeInsets
    /// See `UIEdgeInsets.swiftUIInsets` extension
    var safeAreaInsets: EdgeInsets
    {
        self[SafeAreaInsetsKey.self]
    }
}
