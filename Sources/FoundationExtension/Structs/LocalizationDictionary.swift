//
//  LocalizationDictionary.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

import SwiftExtension
import Foundation

public typealias LanguageCodeKey = String
public typealias LocalizedStringValue = String
public typealias LocalizationDictionary = Dictionary<LanguageCodeKey, LocalizedStringValue>
public extension LocalizationDictionary
{
    @usableFromInline
    internal func check_locale(_ locale: Locale) -> LocalizedStringValue?
    {
        // simple check
        if let l_string = self[locale.identifier]
        {
            return l_string
        }
        
        // require lang code
        guard let languageCode = locale.languageCode
        else {return nil}
        
        // check for Script, this format is used by lproj files
        if let regionCode = locale.regionCode, let l_string = self["\(languageCode)-\(regionCode)"]
        {
            return l_string
        }
        else // Fallback on language code
        if let languageCode = locale.languageCode, let l_string = self[languageCode]
        {
            return l_string
        }
        
        return nil
    }
    
    @inlinable
    subscript(_ locale: Locale) -> LocalizedStringValue
    {
        // check provided locale
        if let l_string = check_locale(locale)
        {
            return l_string
        }
        else // fallback on current locale if provided locale is not current
        if Locale.current != locale
        {
            if let l_string = check_locale(Locale.current)
            {
                return l_string
            }
        }
        else // fallback on preffered localizations
        {
            for localization in Bundle.main.preferredLocalizations
            {
                let locale_ = Locale(identifier: localization) // create locale from localization
                if let l_string = check_locale(locale_)
                {
                    return l_string
                }
            }
        }
        
        // return any value if there are any values at all
        return self.first?.value ?? ""
    }
}

