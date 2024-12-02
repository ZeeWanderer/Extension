//
//  ClearBackgroundViewModifier.swift
//
//
//  Created by Maksym Kulyk on 21.05.2024.
//

import SwiftUI

#if canImport(UIKit)
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
