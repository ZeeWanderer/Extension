//
//  Environment.swift
//  
//
//  Created by Maksym Kulyk on 09.03.2022.
//

import SwiftUI

public struct SafeAreaInsetsKey: EnvironmentKey
{
    public static var defaultValue: EdgeInsets
    {
        UIApplication.shared.keyWindow_?.safeAreaInsets.swiftUIInsets ?? EdgeInsets()
    }
}

public extension EnvironmentValues
{
    var safeAreaInsets: EdgeInsets
    {
        self[SafeAreaInsetsKey.self]
    }
}
