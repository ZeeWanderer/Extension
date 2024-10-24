//
//  SafeAreaInsetsKey.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import UIKitExtension
import SwiftUI

public struct SafeAreaInsetsKey: @preconcurrency EnvironmentKey
{
    @inlinable @MainActor
    public static var defaultValue: EdgeInsets
    {
        UIApplication.shared.keySceneWindow?.safeAreaInsets.swiftUIInsets ?? EdgeInsets()
    }
}
