//
//  ClearBackgroundView.swift
//
//
//  Created by zeewanderer on 21.05.2024.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

/// A hack to get access to `UIView.backgroundColor` of modal superview. Remove when this functionality beomes available in SwiftUI.
public struct ClearBackgroundView: UIViewRepresentable
{
    @inlinable
    public init() {} // for @inlinable

    @inlinable
    public func makeUIView(context: Context) -> some UIView
    { P_View() }

    @inlinable
    public func updateUIView(_ uiView: UIViewType, context: Context)
    {
    }

    /// Waits for hierarchy attachment through UIKit's lifecycle callbacks.
    @usableFromInline
    internal final class P_View: UIView
    {
        override func didMoveToSuperview()
        {
            super.didMoveToSuperview()
            superview?.superview?.backgroundColor = .clear
        }

        override func didMoveToWindow()
        {
            super.didMoveToWindow()
            superview?.superview?.backgroundColor = .clear
        }
    }
}
#endif
