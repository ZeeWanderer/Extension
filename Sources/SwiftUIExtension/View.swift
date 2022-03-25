//
//  View.swift
//  
//
//  Created by Maksym Kulyk on 19.11.2021.
//

import SwiftUI

// MARK: - UIViewRepresentables
public struct ClearBackgroundView: UIViewRepresentable
{
    public func makeUIView(context: Context) -> some UIView
    {
        let view = UIView()
        Task { @MainActor in
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context)
    {
    }
}

// MARK: - ViewModifiers
public struct ClearBackgroundViewModifier: ViewModifier
{
    public init() {} // for @inlinable
    
    public func body(content: Content) -> some View
    {
        content
            .background(ClearBackgroundView())
    }
}

// MARK: - View
public extension View
{
    
    // MARK: Keyboard
    @inlinable
    func endTextEditing()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
    
    // MARK: Notifications
    @inlinable
    func onNotification(_ notificationName: Notification.Name, perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onReceive(NotificationCenter.default.publisher(for: notificationName), perform: action)
    }
    
    @inlinable
    func onDidEnterBackgroundNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.didEnterBackgroundNotification,
            perform: action
        )
    }
    
    @inlinable
    func onWillEnterForegroundNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.willEnterForegroundNotification,
            perform: action
        )
    }
    
    // MARK: Modifiers
    @inlinable
    func glow(radius: CGFloat = 5) -> some View
    {
        self
            .overlay(self.blur(radius: radius))
    }
    
    @inlinable
    func glow(color: Color = .yellow, radius: CGFloat = 5) -> some View
    {
        self
            .shadow(color: color, radius: radius / 2)
            .shadow(color: color, radius: radius / 2)
    }
    
    @inlinable
    func clearModalBackground() -> some View
    {
        self.modifier(ClearBackgroundViewModifier())
    }
}

// MARK: - View DEBUG
public extension View
{
    
    // MARK: Debug Actions
    @inlinable
    func debugAction(_ closure: () -> Void) -> Self
    {
#if DEBUG
        closure()
#endif
        
        return self
    }
    
    @inlinable
    func debugPrint(_ value: Any) -> Self
    {
        debugAction { print(value) }
    }
    
    // MARK: Debug Modifiers
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
