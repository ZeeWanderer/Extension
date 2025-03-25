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
    
    @usableFromInline internal static let impact_generator_light: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @usableFromInline internal static let impact_generator_medium: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @usableFromInline internal static let impact_generator_heavy: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @usableFromInline internal static let impact_generator_soft: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    @usableFromInline internal static let impact_generator_rigid: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    @usableFromInline internal static let notification_generator = UINotificationFeedbackGenerator()
    
    @usableFromInline internal static let selection_generator = UISelectionFeedbackGenerator()
    //SystemSoundID(1306)
    @usableFromInline nonisolated internal static let sounds_key_pressed:SystemSoundID = SystemSoundID(1104)// [SystemSoundID(1104), SystemSoundID(1105)]
    
    @usableFromInline internal static var bShouldUseVibrationDyn: (()->Bool)? = nil
    @usableFromInline internal static var bShouldUseGeneralSoundEffectsDyn: (()->Bool)? = nil
    
    @usableFromInline internal static var bShouldUseVibration: Bool? = nil
    @usableFromInline internal static var bShouldUseGeneralSoundEffects: Bool? = nil
    
    @usableFromInline
    internal static func should_use_vibration()->Bool
    {
        if let bShouldUseVibration = bShouldUseVibration
        {
            return bShouldUseVibration
        }
        
        
        if let bShouldUseVibrationDyn = bShouldUseVibrationDyn
        {
            return bShouldUseVibrationDyn()
        }
        
        return true
    }
    
    @usableFromInline
    internal static func should_use_sound()->Bool
    {
        if let bShouldUseGeneralSoundEffects = bShouldUseGeneralSoundEffects
        {
            return bShouldUseGeneralSoundEffects
        }
        
        if let bShouldUseGeneralSoundEffectsDyn = bShouldUseGeneralSoundEffectsDyn
        {
            return bShouldUseGeneralSoundEffectsDyn()
        }
        
        return true
    }
    
    // MARK: - Interface
    
    @inlinable
    public static func set_dynamic_vibration_preference(_ closure: @escaping ()->Bool)
    {
        bShouldUseVibrationDyn = closure
    }
    
    @inlinable
    public static func set_dynamic_sound_preference(_ closure: @escaping ()->Bool)
    {
        bShouldUseGeneralSoundEffectsDyn = closure
    }
    
    @inlinable
    public static func set_dynamic_preferences(vibration: @escaping ()->Bool, sound: @escaping ()->Bool)
    {
        bShouldUseVibrationDyn = vibration
        bShouldUseGeneralSoundEffectsDyn = sound
    }
    
    @inlinable
    public static func set_static_preferences(vibration: Bool, sound: Bool)
    {
        bShouldUseVibration = vibration
        bShouldUseGeneralSoundEffects = sound
    }
    
    @inlinable
    public static func prepare_selection_generator() async
    {
        if !should_use_vibration()
        {
            return
        }
        
        selection_generator.prepare()
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
        if !should_use_vibration()
        {
            return
        }
        
        notification_generator.prepare()
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
        if !should_use_vibration()
        {
            return
        }
        
        switch fs
        {
        case .light:
            impact_generator_light.prepare()
        case .medium:
            impact_generator_medium.prepare()
        case .heavy:
            impact_generator_heavy.prepare()
        case .soft:
            impact_generator_soft.prepare()
        case .rigid:
            impact_generator_rigid.prepare()
        @unknown default:
            impact_generator_medium.prepare()
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
        if !should_use_vibration()
        {
            return
        }
        
        impact_generator_light.prepare()
        impact_generator_medium.prepare()
        impact_generator_heavy.prepare()
        impact_generator_soft.prepare()
        impact_generator_rigid.prepare()
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
        if !should_use_sound()
        {
            return
        }
        
        let sound = sounds_key_pressed
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
        if !should_use_vibration()
        {
            return
        }
        selection_generator.selectionChanged()
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
        if !should_use_vibration()
        {
            return
        }
        
        notification_generator.notificationOccurred(ft)
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
        if !should_use_vibration()
        {
            return
        }
        
        switch fs
        {
        case .light:
            impact_generator_light.impactOccurred()
        case .medium:
            impact_generator_medium.impactOccurred()
        case .heavy:
            impact_generator_heavy.impactOccurred()
        case .soft:
            impact_generator_soft.impactOccurred()
        case .rigid:
            impact_generator_rigid.impactOccurred()
        @unknown default:
            impact_generator_medium.impactOccurred()
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
        if !should_use_vibration()
        {
            return
        }
        
        switch fs
        {
        case .light:
            impact_generator_light.impactOccurred(intensity: intensity)
        case .medium:
            impact_generator_medium.impactOccurred(intensity: intensity)
        case .heavy:
            impact_generator_heavy.impactOccurred(intensity: intensity)
        case .soft:
            impact_generator_soft.impactOccurred(intensity: intensity)
        case .rigid:
            impact_generator_rigid.impactOccurred(intensity: intensity)
        @unknown default:
            impact_generator_medium.impactOccurred(intensity: intensity)
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
