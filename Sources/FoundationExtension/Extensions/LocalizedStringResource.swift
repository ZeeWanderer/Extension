//
//  LocalizedStringResource.swift
//  Extension
//
//  Created by zeewanderer on 17.10.2025.
//

import Foundation

public extension LocalizedStringResource
{
    @inlinable
    func locale(_ locale: Locale) -> Self
    {
        var newSelf = self
        newSelf.locale = locale
        return newSelf
    }
}
