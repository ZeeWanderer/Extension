//
//  KeyboardHelper.swift
//
//
//  Created by zeewanderer on 21.05.2024.
//

#if canImport(UIKit)
import SwiftUI
import Observation
import osExtension
import os

/// Helper class that listens to keyboard notifications and provides observable keyboard height and a number of helper functions
/// - Note: Does not use `withAnimation`, so animation needs to be set by end user via `animation`.
@Observable @MainActor
public final class KeyboardHelper: LogSubsystemCategoryProtocol
{
    public typealias Subsystem = SwiftUIExtension
    
    nonisolated public static let logger = makeLogger()
    nonisolated public static let signposter = makeSignposter()
    
    public enum Event: String, Sendable
    {
        case willShow
        case didShow
        case willHide
        case didHide
        case willChangeFrame
        case didChangeFrame
    }

    @usableFromInline
    internal struct EventData: Sendable
    {
        @usableFromInline let event: Event
        @usableFromInline let beginFrame: CGRect?
        @usableFromInline let endFrame: CGRect?
        @usableFromInline let animationDuration: CGFloat?
        @usableFromInline let animationCurve: UIView.AnimationCurve?
        @usableFromInline let isLocal: Bool?
        
        @usableFromInline
        init(event: Event, notification: Notification)
        {
            let userInfo = notification.userInfo
            self.event = event
            self.beginFrame = userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect
            self.endFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            self.animationDuration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber).map { CGFloat(truncating: $0) }
            self.animationCurve = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber).flatMap { UIView.AnimationCurve(rawValue: Int(truncating: $0)) }
            self.isLocal = (userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? NSNumber).map { $0.boolValue }
        }
    }
    
    public struct KeyboardState: Sendable, Equatable
    {
        public var event: Event?
        public var beginFrame: CGRect
        public var endFrame: CGRect
        public var animationDuration: CGFloat
        public var animationCurve: UIView.AnimationCurve
        public var isLocal: Bool
        
        public static let empty = KeyboardState(event: nil,
                                               beginFrame: .zero,
                                               endFrame: .zero,
                                               animationDuration: 0.25,
                                               animationCurve: .easeOut,
                                               isLocal: true)
        
        @usableFromInline
        func merged(with data: EventData) -> KeyboardState
        {
            var next = self
            next.event = data.event
            if let begin = data.beginFrame { next.beginFrame = begin }
            if let end = data.endFrame { next.endFrame = end }
            if let duration = data.animationDuration { next.animationDuration = duration }
            if let curve = data.animationCurve { next.animationCurve = curve }
            if let isLocal = data.isLocal { next.isLocal = isLocal }
            return next
        }
    }
    
    public private(set) var state: KeyboardState = .empty
    
    public var keyboardHeight: CGFloat { state.endFrame.height }
    public var beginFrame: CGRect { state.beginFrame }
    public var endFrame: CGRect { state.endFrame }
    public var animationDuration: CGFloat { state.animationDuration }
    public var animationCurve: UIView.AnimationCurve { state.animationCurve }
    public var isLocal: Bool { state.isLocal }
    public var lastEvent: Event? { state.event }
    
    @ObservationIgnored @usableFromInline internal var keyboardEventTask: Task<Void,Never>? = nil
    @ObservationIgnored @usableFromInline internal var keyboardObservers: [NSObjectProtocol] = []
    
    @inlinable
    public var isKeyboardActive: Bool
    {
        keyboardHeight != 0
    }
    
    /// Sends action to hide keyboard if it is not hidden
    /// - Returns: Whether the keyboard will be hidden.
    @inlinable
    @discardableResult public func endTextEditing() -> Bool
    {
        if isKeyboardActive
        {
            return UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                   to: nil, from: nil, for: nil)
        }
        
        return false
    }
    
    /// Provides `Animation` value to match keyboard animation
    @inlinable
    public var animation: Animation
    {
        switch animationCurve
        {
        case .linear:
            return .linear(duration: animationDuration)
        case .easeIn:
            return .easeIn(duration: animationDuration)
        case .easeOut:
            return .easeOut(duration: animationDuration)
        case .easeInOut:
            return .easeInOut(duration: animationDuration)
        @unknown default:
            return .easeOut(duration: animationDuration)
        }
    }
    
    @usableFromInline @MainActor
    internal func updateState(from data: EventData)
    {
        let next = state.merged(with: data)
        if next != state { state = next }
    }
    
    @usableFromInline
    internal func listenForKeyboardNotifications()
    {
        let eventStream = AsyncStream<EventData> { continuation in
            let center = NotificationCenter.default
            var observers: [NSObjectProtocol] = []
            
            func observe(_ name: Notification.Name, _ event: Event)
            {
                let token = center.addObserver(forName: name, object: nil, queue: nil) { notification in
                    continuation.yield(.init(event: event, notification: notification))
                }
                observers.append(token)
            }
            
            observe(UIResponder.keyboardWillShowNotification, .willShow)
            observe(UIResponder.keyboardDidShowNotification, .didShow)
            observe(UIResponder.keyboardWillHideNotification, .willHide)
            observe(UIResponder.keyboardDidHideNotification, .didHide)
            observe(UIResponder.keyboardWillChangeFrameNotification, .willChangeFrame)
            observe(UIResponder.keyboardDidChangeFrameNotification, .didChangeFrame)
            
            self.keyboardObservers = observers
        }
        
        keyboardEventTask = Task { @MainActor [weak self] in
            for await data in eventStream
            {
                guard let self else { break }
                self.updateState(from: data)
                
                switch data.event
                {
                case .willShow:
                    Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard will show: height=\(self.keyboardHeight, privacy: .public) duration=\(self.animationDuration, privacy: .public) curve=\(self.animationCurve.rawValue, privacy: .public) local=\(self.isLocal, privacy: .public)")
                case .didShow:
                    Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard did show: height=\(self.keyboardHeight, privacy: .public)")
                case .willHide:
                    Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard will hide")
                case .didHide:
                    Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard did hide")
                case .willChangeFrame:
                    Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard will change frame: begin=\(self.beginFrame.debugDescription, privacy: .public) end=\(self.endFrame.debugDescription, privacy: .public)")
                case .didChangeFrame:
                    Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard did change frame: end=\(self.endFrame.debugDescription, privacy: .public)")
                }
            }
        }
    }
    
    public init()
    {
        self.listenForKeyboardNotifications()
    }
    
    @inlinable
    isolated deinit
    {
        self.keyboardEventTask?.cancel()
        for token in self.keyboardObservers {
            NotificationCenter.default.removeObserver(token)
        }
        self.keyboardObservers.removeAll()
    }
}

public extension KeyboardHelper {
    nonisolated static let shared: KeyboardHelper = MainActor.enforceIsolated { KeyboardHelper() }
}
#endif
