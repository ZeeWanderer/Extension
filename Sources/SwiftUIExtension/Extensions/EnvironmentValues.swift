//
//  EnvironmentValues.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import SwiftUI

#if canImport(UIKit)
public extension EnvironmentValues
{
    /// The current SafeArea EdgeInsets of the scene
    ///
    /// This value is set to provide observable EdgeInsets
    /// See `UIEdgeInsets.swiftUIInsets` extension
    @inlinable
    var safeAreaInsets: EdgeInsets
    {
        self[SafeAreaInsetsKey.self]
    }
}
#endif
