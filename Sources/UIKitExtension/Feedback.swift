//
//  Feedback.swift
//  
//
//  Created by Maksym Kulyk on 13.04.2022.
//

import UIKit
import AVFoundation

public final class FeedbackHelper
{
    //TODO: AudioServicesPlaySystemSound(SystemSoundID(1104))
    
    @usableFromInline internal static let impact_generator_light: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @usableFromInline internal static let impact_generator_medium: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @usableFromInline internal static let impact_generator_heavy: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @usableFromInline internal static let impact_generator_soft: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    @usableFromInline internal static let impact_generator_rigid: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    @usableFromInline internal static let notification_generator = UINotificationFeedbackGenerator()
    
    @usableFromInline internal static let selection_generator = UISelectionFeedbackGenerator()
    //SystemSoundID(1306)
    @usableFromInline internal static let sounds_key_pressed:SystemSoundID = SystemSoundID(1104)// [SystemSoundID(1104), SystemSoundID(1105)]
    
    @usableFromInline internal static var bShouldUseVibrationDyn: (()->Bool)? = nil
    @usableFromInline internal static var bShouldUseGeneralSoundEffectsDyn: (()->Bool)? = nil
    
    @usableFromInline internal static var bShouldUseVibration: Bool? = nil
    @usableFromInline internal static var bShouldUseGeneralSoundEffects: Bool? = nil
    
    @inlinable
    static func set_dynamic_vibration_preference(_ closure: @escaping ()->Bool)
    {
        bShouldUseVibrationDyn = closure
    }
    
    @inlinable
    static func set_dynamic_sound_preference(_ closure: @escaping ()->Bool)
    {
        bShouldUseGeneralSoundEffectsDyn = closure
    }
    
    @inlinable
    static func set_dynamic_preferences(vibration: @escaping ()->Bool, sound: @escaping ()->Bool)
    {
        bShouldUseVibrationDyn = vibration
        bShouldUseGeneralSoundEffectsDyn = sound
    }
    
    @inlinable
    static func set_static_preferences(vibration: Bool, sound: Bool)
    {
        bShouldUseVibration = vibration
        bShouldUseGeneralSoundEffects = sound
    }
    
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
    
    @inlinable
    public static func prepare_selection_generator()
    {
        if !should_use_vibration()
        {
            return
        }
        
        selection_generator.prepare()
    }
    
    @inlinable
    public static func prepare_notification_generator()
    {
        if !should_use_vibration()
        {
            return
        }
        
        notification_generator.prepare()
    }
    
    @inlinable
    public static func prepare_impact_generator(_ fs: UIImpactFeedbackGenerator.FeedbackStyle)
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
    public static func prepare_impact_generators()
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
    public static func play_button_sound()
    {
        if !should_use_sound()
        {
            return
        }
        
        let sound = sounds_key_pressed
        AudioServicesPlaySystemSound(sound)
    }
    
    @inlinable
    public static func selectionChanged()
    {
        if !should_use_vibration()
        {
            return
        }
        selection_generator.selectionChanged()
    }
    
    @inlinable
    public static func notificationOccurred(_ ft: UINotificationFeedbackGenerator.FeedbackType)
    {
        if !should_use_vibration()
        {
            return
        }
        
        notification_generator.notificationOccurred(ft)
    }
    
    @inlinable
    public static func impactOccurred(_ fs: UIImpactFeedbackGenerator.FeedbackStyle)
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
    public static func impactOccurred(_ fs: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat)
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
}
