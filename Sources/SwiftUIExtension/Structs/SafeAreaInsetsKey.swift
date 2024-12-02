//
//  SafeAreaInsetsKey.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import SwiftUI
#if canImport(UIKitExtension)
import UIKitExtension

public struct SafeAreaInsetsKey: @preconcurrency EnvironmentKey
{
    @inlinable @MainActor
    public static var defaultValue: EdgeInsets
    {
        UIApplication.shared.keySceneWindow?.safeAreaInsets.swiftUIInsets ?? EdgeInsets()
    }
}
#endif
