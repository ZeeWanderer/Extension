//
//  View+DEBUG.swift
//
//
//  Created by Maksym Kulyk on 21.05.2024.
//

import SwiftUI

public extension View
{
    // MARK: Actions
    @inlinable
    func debugAction(_ closure: () -> Void) -> Self
    {
#if DEBUG
        closure()
#endif
        return self
    }
    
    @inlinable
    func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") -> Self
    {
        debugAction { print(items, separator: separator, terminator: terminator) }
    }
    
    // MARK: Modifiers
    @inlinable
    func debugModifier(_ modifier: (Self) -> some View) -> some View
    {
#if DEBUG
        return modifier(self)
#else
        return self
#endif
    }
    
    @inlinable
    func debugOnAppear(_ closure: @escaping () -> Void) -> some View
    {
        debugModifier { view in
            view.onAppear(perform: closure)
        }
    }
    
    @inlinable
    func debugOnDisappear(_ closure: @escaping () -> Void) -> some View
    {
        debugModifier { view in
            view.onDisappear(perform: closure)
        }
    }
    
    @inlinable
    func debugOnAppearPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") -> some View
    {
        debugOnAppear {
            print(items, separator: separator, terminator: terminator)
        }
    }
    
    @inlinable
    func debugOnDisappearPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") -> some View
    {
        debugOnDisappear {
            print(items, separator: separator, terminator: terminator)
        }
    }
    
    @inlinable
    func debugRect(color: Color = .red, width: CGFloat = 1) -> some View
    {
        debugModifier { view in
            view.overlay(Rectangle().stroke(color, lineWidth: width))
        }
    }
    
    @inlinable
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View
    {
        debugModifier { view in
            view.border(color, width: width)
        }
    }
    
    @inlinable
    func debugBackground(_ color: Color = .red) -> some View
    {
        debugModifier { view in
            view.background(color)
        }
    }
}
