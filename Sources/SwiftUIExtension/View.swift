//
//  View.swift
//  
//
//  Created by Maksym Kulyk on 19.11.2021.
//

import SwiftUI

// MARK: - UIViewRepresentables
/// A hack to get access to `UIView.backgroundColor` of modal superview. Remove when this functionality beomes available in SwiftUI.
public struct ClearBackgroundView: UIViewRepresentable
{
    @inlinable
    public init() {} // for @inlinable
    
    @inlinable
    public func makeUIView(context: Context) -> some UIView
    {
        let view = UIView()
        Task {
            await MainActor.run {
                view.superview?.superview?.backgroundColor = .clear
            }
        }
        return view
    }
    
    @inlinable
    public func updateUIView(_ uiView: UIViewType, context: Context)
    {
    }
}

// MARK: - ViewModifiers
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

// MARK: - Views
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

// MARK: - View
public extension View
{
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
    
    @inlinable
    func onDidReceiveMemoryWarningNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.didReceiveMemoryWarningNotification,
            perform: action
        )
    }
    
    @inlinable
    func onDidFinishLaunchingNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.didFinishLaunchingNotification,
            perform: action
        )
    }
    
    @inlinable
    func onWillTerminateNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.willTerminateNotification,
            perform: action
        )
    }
    
    // MARK: Modifiers
    /// Conditionaly executes closure.
    /// - Note: Beware, this modifies view in a way that changes it's identifier.
    @inlinable
    @ViewBuilder func `if`<Content>(_ condition: Bool, transform: (Self) -> Content) -> some View where Content : View
    {
        if condition
        {
            transform(self)
        }
        else
        {
            self
        }
    }
    
    /// Made for redibility. Conditionaly executes closure, inverses the condition.
    /// Intended for use after `if` with the same condition to promote readibility. Equivalent to `if(!condition)`.
    /// - Note: Beware, this modifies view in a way that changes it's identifier.
    @inlinable
    @ViewBuilder func `else`<Content>(_ condition: Bool, transform: (Self) -> Content) -> some View where Content : View
    {
        self.if(!condition, transform: transform)
    }
    
    /// Applies glow determined by the View content with radius of `radius`.
    @inlinable
    func glow(radius: CGFloat = 5) -> some View
    {
        self.overlay(self.blur(radius: radius))
    }
    
    /// Applies glow of color `color` with radius of `radius`. Uses double `.shadow()` with halved radius.
    @inlinable
    func glow(color: Color = .yellow, radius: CGFloat = 5) -> some View
    {
        self.shadow(color: color, radius: radius / 2)
            .shadow(color: color, radius: radius / 2)
    }
    
    /// Clears background on modal views. Applies ``ClearBackgroundViewModifier``.
    @inlinable
    func clearModalBackground() -> some View
    {
        self.modifier(ClearBackgroundViewModifier())
    }
    
    /// Applies `.hidden()` to view on provided condition
    @inlinable
    func hidden(_ hidden: Bool) -> some View
    {
        self.if(hidden) { view in
            self.hidden()
        }
    }
    
    // MARK: Navigation
    /// Navigate to `destination` using a `binding`. Destination is instantiated imideately and repeatedly on any state changes.
    @inlinable
    func navigate<Destination>(using binding: Binding<Bool>, @ViewBuilder destination: () -> Destination, isDetailLink: Bool = true) -> some View where Destination : View
    {
        self.background(NavigationLink(destination: destination(), isActive: binding, label: EmptyView.init).isDetailLink(isDetailLink))
    }
    
    /// Navigate to `destination` using a `binding`. Destination is warapped into ``LazyView`` to avoid unnececery initis.
    @inlinable
    func lazyNavigate<Destination>(using binding: Binding<Bool>, @ViewBuilder destination: @escaping () -> Destination, isDetailLink: Bool = true) -> some View where Destination : View
    {
        self.background(NavigationLink(destination: LazyView(destination), isActive: binding, label: EmptyView.init).isDetailLink(isDetailLink))
    }
    
    // MARK: Compatibility
    /// Backwards compatible `task` call.
    @inlinable
    @ViewBuilder func compat_task(_ action: @escaping () async -> Void) -> some View
    {
        if #available(iOS 15, *)
        {
            self.task {
                await action()
            }
        }
        else
        {
            self.onAppear {
                Task {
                    await action()
                }
            }
        }
    }
    
    /// Backwards compatible `overlay` call.
    @inlinable
    @ViewBuilder func compat_overlay<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V: View
    {
        if #available(iOS 15, *)
        {
            self.overlay(alignment: alignment, content: content)
        }
        else
        {
            self.overlay(content(), alignment: alignment)
        }
    }
    
    /// Backwards compatible `background` call.
    @inlinable
    @ViewBuilder func compat_background<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V: View
    {
        if #available(iOS 15, *)
        {
            self.background(alignment: alignment, content: content)
        }
        else
        {
            self.background(content(), alignment: alignment)
        }
    }
}
