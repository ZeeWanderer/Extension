//
//  KeyboardHeightHelper.swift
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
public final class KeyboardHeightHelper: LogSubsystemCategoryProtocol
{
    public typealias Subsystem = SwiftUIExtension
    
    nonisolated public static let logger = makeLogger()
    nonisolated public static let signposter = makeSignposter()
    
    public var keyboardHeight: CGFloat = 0
    
    @ObservationIgnored @usableFromInline internal var duration: CGFloat = 0.25
    @ObservationIgnored @usableFromInline internal var curve: UIView.AnimationCurve = .easeOut
    @ObservationIgnored @usableFromInline internal var keyboardWillShowNotificationTask: Task<Void,Never>? = nil
    @ObservationIgnored @usableFromInline internal var keyboardWillHideNotificationTask: Task<Void,Never>? = nil
    
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
        switch curve
        {
        case .linear:
            return .linear(duration: duration)
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .easeInOut:
            return .easeInOut(duration: duration)
        @unknown default:
            return .easeOut(duration: duration)
        }
    }
    
    @usableFromInline @MainActor
    internal func set_keyboardHeight(_ value: CGFloat) async
    {
        self.keyboardHeight = value
    }
    
    @usableFromInline
    internal func listenForKeyboardNotifications()
    {
        keyboardWillShowNotificationTask = Task
        {
            [weak self] in
            for await data: (UIView.AnimationCurve, NSNumber, CGFloat) in NotificationCenter.default.notifications(named: UIResponder.keyboardWillShowNotification)
                .compactMap({ notification in
                    guard let userInfo = notification.userInfo,
                          let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                          let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
                          let curve_raw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber,
                          let curve = UIView.AnimationCurve(rawValue: Int(truncating: curve_raw))
                    else { return nil }
                    
                    return (curve, duration, keyboardRect.height)
                })
            {
                guard let self else { break }
                let (curve, duration, height) = data
                
                self.curve = curve
                self.duration = CGFloat(truncating: duration)
                Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard will show: height=\(height, privacy: .public) duration=\(self.duration, privacy: .public) curve=\(curve.rawValue, privacy: .public)")
                
                await self.set_keyboardHeight(height)
            }
        }
        
        keyboardWillHideNotificationTask = Task
        {
            [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillHideNotification).map({ _ in true })
            {
                guard let self else { break }
                Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard will hide")
                await self.set_keyboardHeight(0)
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
        self.keyboardWillShowNotificationTask?.cancel()
        self.keyboardWillHideNotificationTask?.cancel()
    }
}
#endif
