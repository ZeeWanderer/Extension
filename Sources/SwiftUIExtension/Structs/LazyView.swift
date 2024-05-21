//
//  LazyView.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import SwiftUI

/// Delays instantiation of wrapped view untill it is actually displayed.
/// - Note: May degrade perfomance, use carefully.
public struct LazyView<Content>: View where Content : View
{
    public let build: () -> Content
    
    @inlinable
    public init(_ build: @autoclosure @escaping () -> Content)
    {
        self.build = build
    }
    
    @inlinable
    public init(_ build: @escaping () -> Content)
    {
        self.build = build
    }
    
    @inlinable
    public var body: Content
    {
        build()
    }
}
