//
//  SafeAreaInsetsKey.swift
//  
//
//  Created by zeewanderer on 20.05.2024.
//

#if canImport(UIKit)
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
#endif
