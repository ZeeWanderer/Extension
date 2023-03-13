//
//  Swift.swift
//  
//
//  Created by Maksym Kulyk on 13.03.2023.
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
