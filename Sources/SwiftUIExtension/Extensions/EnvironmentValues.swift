//
//  EnvironmentValues.swift
//  
//
//  Created by zeewanderer on 20.05.2024.
//

import SwiftUI

public extension EnvironmentValues
{
#if canImport(UIKit)
    /// The current SafeArea EdgeInsets of the scene
    ///
    /// This value is set to provide observable EdgeInsets
    /// See `UIEdgeInsets.swiftUIInsets` extension
    @inlinable
    var safeAreaInsets: EdgeInsets
    {
        self[SafeAreaInsetsKey.self]
    }
#endif
}
