//
//  View.swift
//  
//
//  Created by zeewanderer on 19.11.2021.
//

import SwiftUI
#if canImport(UIKit)
import UIKitExtension
#endif
import CoreGraphicsExtension
import GeneralExtensions

// MARK: - View
public extension View
{
 
#if canImport(UIKit)
    // MARK: Actions
    @MainActor @inlinable
    @discardableResult func endTextEditing() -> Bool
    {
        return UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                               to: nil, from: nil, for: nil)
    }
    
    
    @MainActor @inlinable
    func screenShot(frame:CGRect, afterScreenUpdates: Bool) -> UIImage {
        let hosting = UIHostingController(rootView: self)
        hosting.overrideUserInterfaceStyle = UIApplication.shared.keySceneWindow?.overrideUserInterfaceStyle ?? .unspecified
        hosting.view.frame = frame
        return hosting.view.screenShot(afterScreenUpdates: afterScreenUpdates)
    }
#endif
    
    // MARK: Notifications
    @MainActor @inlinable
    func onNotification(_ notificationName: Notification.Name, perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onReceive(NotificationCenter.default.publisher(for: notificationName), perform: action)
    }
    
#if canImport(UIKit)
    @MainActor @inlinable
    func onDidEnterBackgroundNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.didEnterBackgroundNotification,
            perform: action
        )
    }
    
    @MainActor @inlinable
    func onWillEnterForegroundNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.willEnterForegroundNotification,
            perform: action
        )
    }
    
    @MainActor @inlinable
    func onDidReceiveMemoryWarningNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.didReceiveMemoryWarningNotification,
            perform: action
        )
    }
    
    @MainActor @inlinable
    func onDidFinishLaunchingNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.didFinishLaunchingNotification,
            perform: action
        )
    }
    
    @MainActor @inlinable
    func onWillTerminateNotification(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some View
    {
        onNotification (
            UIApplication.willTerminateNotification,
            perform: action
        )
    }
#endif
    
    // MARK: Modifiers
    /// Conditionaly executes closure.
    /// - Note: Beware, this modifies view in a way that changes it's identifier.
    @inlinable
    @ViewBuilder func `if`(_ condition: Bool, @ViewBuilder transform: (Self) -> some View) -> some View
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
    @ViewBuilder func `else`(_ condition: Bool, @ViewBuilder transform: (Self) -> some View) -> some View
    {
        self.if(!condition, transform: transform)
    }
    
    @inlinable
    func transform(@ViewBuilder _ transform: (Self) -> some View) -> some View
    {
        transform(self)
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
    
#if canImport(UIKit)
    /// Clears background on modal views. Applies ``ClearBackgroundViewModifier``.
    @inlinable
    func clearModalBackground() -> some View
    {
        self.modifier(ClearBackgroundViewModifier())
    }
#endif
    
    /// Applies `.hidden()` to view on provided condition
    @inlinable
    func hidden(_ hidden: Bool) -> some View
    {
        self.if(hidden) { view in
            self.hidden()
        }
    }
    
    
    @inlinable
    @ViewBuilder func hiddenOnRelease() -> some View
    {
        self
            .debugBorder()
            .hidden(!Config.isTestFlightOrDebug)
    }
    
    /// Flips view across the specified axis.
    /// - Note: Uses `rotation3DEffect`
    @inlinable
    func flipped(_ axis: Axis) -> some View
    {
        switch axis
        {
        case .horizontal:
            return self.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        case .vertical:
            return self.rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
        }
    }
    
    /// Positions this view within an invisible frame with the specified size.
    @inlinable
    func frame(size: CGSize? = nil, alignment: Alignment = .center) -> some View
    {
        self.frame(width: size?.width, height: size?.height, alignment: alignment)
    }
    
    /// Positions this view within an invisible frame having the specified size constraints.
    @inlinable
    func frame(minSize: CGSize? = nil, idealSize: CGSize? = nil, maxSize: CGSize? = nil, alignment: Alignment = .center) -> some View
    {
        self.frame(minWidth: minSize?.width, idealWidth: idealSize?.width, maxWidth: maxSize?.width, minHeight: minSize?.height, idealHeight: idealSize?.height, maxHeight: maxSize?.height, alignment: alignment)
    }
    
    /// Frames and postions view in a geven rect.
    /// - Parameter rect: A rectangle to position View in. Must be specified in View's parent coordinate system.
    @inlinable
    func position(in rect: CGRect, alignment: Alignment = .center) -> some View
    {
        self
            .frame(size: rect.size, alignment: alignment)
            .position(rect.center)
    }
    
    /// Applies shadow with given Shadow data.
    @inlinable
    func shadow(data: Shadow) -> some View
    {
        self
            .shadow(color: data.color, radius: data.radius, x: data.x, y: data.y)
    }
    
#if canImport(UIKit)
    /// Applies `defersSystemGestures` on given `edges` if `iOS >= 16.0`
    @inlinable
    @ViewBuilder func defersSystemGesturesIfAvailable(on edges: Edge.Set = .all) -> some View
    {
        if #available(iOS 16.0, *)
        {
            self
                .defersSystemGestures(on: edges)
        }
        else
        {
            self
        }
    }
    
    @MainActor @inlinable
    @ViewBuilder func screenShot(_ trigger: Binding<Bool>, closure: @escaping (UIImage)->Void, envClosure: ((Self) -> some View)? = nil) -> some View {
        self
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: trigger.wrappedValue, perform: { value in
                            @ViewBuilder
                            func envViewBuilder(_ view: Self) -> some View
                            {
                                if let envClosure { envClosure(view) }
                                else { view }
                            }
                            
                            let view_ = envViewBuilder(self)
                            
                            let image = view_.screenShot(frame: proxy.frame(in: .global), afterScreenUpdates: true)
                            
                            closure(image)
                            
                            return
                        })
                }
            }
    }
    
    // MARK: Navigation
    /// Navigate to `destination` using a `binding`. Destination is instantiated imideately and repeatedly on any state changes.
    @inlinable
    func navigate<Destination>(using binding: Binding<Bool>, @ViewBuilder destination: () -> Destination, isDetailLink: Bool = true) -> some View where Destination : View
    {
        self.background
        {
            NavigationLink(destination: destination(), isActive: binding, label: EmptyView.init)
                .isDetailLink(isDetailLink)
                .hidden()
        }
    }
    
    /// Navigate to `destination` using a `binding`. Destination is warapped into ``LazyView`` to avoid unnececery initis.
    @inlinable
    func lazyNavigate(using binding: Binding<Bool>, @ViewBuilder destination: @escaping () -> some View, isDetailLink: Bool = true) -> some View
    {
        self.background
        {
            NavigationLink(destination: LazyView(destination), isActive: binding, label: EmptyView.init)
                .isDetailLink(isDetailLink)
                .hidden()
        }
    }
#endif
    
    // MARK: Compatibility - DEPRECATED
    /// Backwards compatible `task` call.
    @available(*, deprecated, renamed: "task(_:)")
    @inlinable
    @ViewBuilder func compat_task(_ action: @Sendable @escaping () async -> Void) -> some View
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
    @available(*, deprecated, renamed: "overlay(alignment:content:)")
    @inlinable
    @ViewBuilder func compat_overlay(alignment: Alignment = .center, @ViewBuilder content: () -> some View) -> some View
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
    @available(*, deprecated, renamed: "background(alignment:content:)")
    @inlinable
    @ViewBuilder func compat_background(alignment: Alignment = .center, @ViewBuilder content: () -> some View) -> some View
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
    
    /// Backwards compatible `mask` call.
    /// - Note: `alignment` parameter is not used pre iOS 15.
    @available(*, deprecated, renamed: "mask(alignment:_:)")
    @inlinable
    @ViewBuilder // use `some` when XCode 14 comes out
    func compat_mask<Mask>(alignment: Alignment = .center, @ViewBuilder _ mask: () -> some View) -> some View
    {
        if #available(iOS 15, *)
        {
            self.mask(alignment: alignment, mask)
        }
        else
        {
            self.mask(mask())
        }
    }
}
