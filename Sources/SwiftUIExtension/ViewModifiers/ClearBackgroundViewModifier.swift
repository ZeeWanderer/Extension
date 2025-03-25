//
//  ClearBackgroundViewModifier.swift
//
//
//  Created by zeewanderer on 21.05.2024.
//

#if canImport(UIKit)
import SwiftUI

/// Clears background on modal views. Uses ``ClearBackgroundView``.
public struct ClearBackgroundViewModifier: ViewModifier
{
    @inlinable
    public init() {} // for @inlinable
    
    public func body(content: Content) -> some View
    {
        content
            .background(ClearBackgroundView())
    }
}
#endif
