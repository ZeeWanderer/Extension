//
//  String.swift
//  
//
//  Created by zeewanderer on 21.05.2024.
//

import Foundation
import SwiftUI

public extension String
{
    /// localized key for the string.
    @inlinable
    var localizedKey: LocalizedStringKey
    {
        return LocalizedStringKey(self)
    }
}
