//
//  Debug.swift
//  
//
//  Created by Maksym Kulyk on 05.04.2022.
//

import SwiftUI

// MARK: - View
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
    func debugModifier<T: View>(_ modifier: (Self) -> T) -> some View
    {
#if DEBUG
        return modifier(self)
#else
        return self
#endif
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