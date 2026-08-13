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
    
    @ObservationIgnored @usableFromInline internal var p_duration: CGFloat = 0.25
    @ObservationIgnored @usableFromInline internal var p_curve: UIView.AnimationCurve = .easeOut
    @ObservationIgnored @usableFromInline internal var p_keyboardWillShowNotificationTask: Task<Void,Never>? = nil
    @ObservationIgnored @usableFromInline internal var p_keyboardWillHideNotificationTask: Task<Void,Never>? = nil
    
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
        switch p_curve
        {
        case .linear:
            return .linear(duration: p_duration)
        case .easeIn:
            return .easeIn(duration: p_duration)
        case .easeOut:
            return .easeOut(duration: p_duration)
        case .easeInOut:
            return .easeInOut(duration: p_duration)
        @unknown default:
            return .easeOut(duration: p_duration)
        }
    }
    
    @usableFromInline @MainActor
    internal func p_setKeyboardHeight(_ value: CGFloat) async
    {
        self.keyboardHeight = value
    }
    
    @usableFromInline
    internal func p_listenForKeyboardNotifications()
    {
        p_keyboardWillShowNotificationTask = Task
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
                
                self.p_curve = curve
                self.p_duration = CGFloat(truncating: duration)
                Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard will show: height=\(height, privacy: .public) duration=\(self.p_duration, privacy: .public) curve=\(curve.rawValue, privacy: .public)")
                
                await self.p_setKeyboardHeight(height)
            }
        }
        
        p_keyboardWillHideNotificationTask = Task
        {
            [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillHideNotification).map({ _ in true })
            {
                guard let self else { break }
                Self.logger.debug("\(Self.logScope, privacy: .public) Keyboard will hide")
                await self.p_setKeyboardHeight(0)
            }
        }
    }
    
    public init()
    {
        self.p_listenForKeyboardNotifications()
    }
    
    @inlinable
    isolated deinit
    {
        self.p_keyboardWillShowNotificationTask?.cancel()
        self.p_keyboardWillHideNotificationTask?.cancel()
    }
}

public extension KeyboardHeightHelper {
    static let shared = KeyboardHeightHelper()
}
#endif
