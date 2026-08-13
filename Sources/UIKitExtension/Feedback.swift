//
//  Feedback.swift
//  
//
//  Created by zeewanderer on 13.04.2022.
//

#if canImport(UIKit)
import UIKit
import AVFoundation

/// A simple class made to trigger standard haptic and sound feedbacks
@MainActor public final class FeedbackHelper
{
    // MARK: - Internal
    //TODO: AudioServicesPlaySystemSound(SystemSoundID(1104))
    
    @usableFromInline internal static let p_impactGeneratorLight: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @usableFromInline internal static let p_impactGeneratorMedium: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @usableFromInline internal static let p_impactGeneratorHeavy: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @usableFromInline internal static let p_impactGeneratorSoft: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    @usableFromInline internal static let p_impactGeneratorRigid: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    @usableFromInline internal static let p_notificationGenerator = UINotificationFeedbackGenerator()
    
    @usableFromInline internal static let p_selectionGenerator = UISelectionFeedbackGenerator()
    //SystemSoundID(1306)
    @usableFromInline nonisolated internal static let p_keyPressedSound: SystemSoundID = SystemSoundID(1104)// [SystemSoundID(1104), SystemSoundID(1105)]
    
    @usableFromInline internal static var p_shouldUseVibrationProvider: (() -> Bool)? = nil
    @usableFromInline internal static var p_shouldUseSoundProvider: (() -> Bool)? = nil
    
    @usableFromInline internal static var p_shouldUseVibration: Bool? = nil
    @usableFromInline internal static var p_shouldUseSound: Bool? = nil
    
    @usableFromInline
    internal static func p_shouldUseVibrationPreference() -> Bool
    {
        if let p_shouldUseVibration
        {
            return p_shouldUseVibration
        }
        
        
        if let p_shouldUseVibrationProvider
        {
            return p_shouldUseVibrationProvider()
        }
        
        return true
    }
    
    @usableFromInline
    internal static func p_shouldUseSoundPreference() -> Bool
    {
        if let p_shouldUseSound
        {
            return p_shouldUseSound
        }
        
        if let p_shouldUseSoundProvider
        {
            return p_shouldUseSoundProvider()
        }
        
        return true
    }
    
    // MARK: - Interface
    
    @inlinable
    public static func set_dynamic_vibration_preference(_ closure: @escaping ()->Bool)
    {
        p_shouldUseVibrationProvider = closure
    }
    
    @inlinable
    public static func set_dynamic_sound_preference(_ closure: @escaping ()->Bool)
    {
        p_shouldUseSoundProvider = closure
    }
    
    @inlinable
    public static func set_dynamic_preferences(vibration: @escaping ()->Bool, sound: @escaping ()->Bool)
    {
        p_shouldUseVibrationProvider = vibration
        p_shouldUseSoundProvider = sound
    }
    
    @inlinable
    public static func set_static_preferences(vibration: Bool, sound: Bool)
    {
        p_shouldUseVibration = vibration
        p_shouldUseSound = sound
    }
    
    @inlinable
    public static func prepare_selection_generator() async
    {
        if !p_shouldUseVibrationPreference()
        {
            return
        }
        
        p_selectionGenerator.prepare()
    }
    
    @inlinable
    nonisolated public static func prepare_selection_generator()
    {
        Task
        {
            await prepare_selection_generator()
        }
    }
    
    @inlinable
    public static func prepare_notification_generator() async
    {
        if !p_shouldUseVibrationPreference()
        {
            return
        }
        
        p_notificationGenerator.prepare()
    }
    
    @inlinable
    nonisolated public static func prepare_notification_generator()
    {
        Task
        {
            await prepare_notification_generator()
        }
    }
    
    @inlinable
    public static func prepare_impact_generator(_ fs: UIImpactFeedbackGenerator.FeedbackStyle) async
    {
        if !p_shouldUseVibrationPreference()
        {
            return
        }
        
        switch fs
        {
        case .light:
            p_impactGeneratorLight.prepare()
        case .medium:
            p_impactGeneratorMedium.prepare()
        case .heavy:
            p_impactGeneratorHeavy.prepare()
        case .soft:
            p_impactGeneratorSoft.prepare()
        case .rigid:
            p_impactGeneratorRigid.prepare()
        @unknown default:
            p_impactGeneratorMedium.prepare()
        }
    }
    
    @inlinable
    nonisolated public static func prepare_impact_generator(_ fs: UIImpactFeedbackGenerator.FeedbackStyle)
    {
        Task
        {
            await prepare_impact_generator(fs)
        }
    }
    
    @inlinable
    public static func prepare_impact_generators() async
    {
        if !p_shouldUseVibrationPreference()
        {
            return
        }
        
        p_impactGeneratorLight.prepare()
        p_impactGeneratorMedium.prepare()
        p_impactGeneratorHeavy.prepare()
        p_impactGeneratorSoft.prepare()
        p_impactGeneratorRigid.prepare()
    }
    
    @inlinable
    nonisolated public static func prepare_impact_generators()
    {
        Task
        {
            await prepare_impact_generators()
        }
    }
    
    @inlinable
    public static func play_button_sound() async
    {
        if !p_shouldUseSoundPreference()
        {
            return
        }
        
        let sound = p_keyPressedSound
        AudioServicesPlaySystemSound(sound)
    }
    
    @inlinable
    nonisolated public static func play_button_sound()
    {
        Task
        {
            await play_button_sound()
        }
    }
    
    @inlinable
    public static func selectionChanged() async
    {
        if !p_shouldUseVibrationPreference()
        {
            return
        }
        p_selectionGenerator.selectionChanged()
    }
    
    @inlinable
    nonisolated public static func selectionChanged()
    {
        Task
        {
            await selectionChanged()
        }
    }
    
    @inlinable
    public static func notificationOccurred(_ ft: UINotificationFeedbackGenerator.FeedbackType) async
    {
        if !p_shouldUseVibrationPreference()
        {
            return
        }
        
        p_notificationGenerator.notificationOccurred(ft)
    }
    
    @inlinable
    nonisolated public static func notificationOccurred(_ ft: UINotificationFeedbackGenerator.FeedbackType)
    {
        Task
        {
            await notificationOccurred(ft)
        }
    }
    
    @inlinable
    public static func impactOccurred(_ fs: UIImpactFeedbackGenerator.FeedbackStyle) async
    {
        if !p_shouldUseVibrationPreference()
        {
            return
        }
        
        switch fs
        {
        case .light:
            p_impactGeneratorLight.impactOccurred()
        case .medium:
            p_impactGeneratorMedium.impactOccurred()
        case .heavy:
            p_impactGeneratorHeavy.impactOccurred()
        case .soft:
            p_impactGeneratorSoft.impactOccurred()
        case .rigid:
            p_impactGeneratorRigid.impactOccurred()
        @unknown default:
            p_impactGeneratorMedium.impactOccurred()
        }
    }
    
    @inlinable
    nonisolated public static func impactOccurred(_ fs: UIImpactFeedbackGenerator.FeedbackStyle)
    {
        Task
        {
            await impactOccurred(fs)
        }
    }
    
    @inlinable
    public static func impactOccurred(_ fs: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) async
    {
        if !p_shouldUseVibrationPreference()
        {
            return
        }
        
        switch fs
        {
        case .light:
            p_impactGeneratorLight.impactOccurred(intensity: intensity)
        case .medium:
            p_impactGeneratorMedium.impactOccurred(intensity: intensity)
        case .heavy:
            p_impactGeneratorHeavy.impactOccurred(intensity: intensity)
        case .soft:
            p_impactGeneratorSoft.impactOccurred(intensity: intensity)
        case .rigid:
            p_impactGeneratorRigid.impactOccurred(intensity: intensity)
        @unknown default:
            p_impactGeneratorMedium.impactOccurred(intensity: intensity)
        }
    }
    
    @inlinable
    nonisolated public static func impactOccurred(_ fs: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat)
    {
        Task
        {
            await impactOccurred(fs, intensity: intensity)
        }
    }
}
#endif
