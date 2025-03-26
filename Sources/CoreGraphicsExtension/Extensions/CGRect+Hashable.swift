//
//  CGRect+Hashable.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

extension CGRect: @retroactive Hashable
{
    @inlinable
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(self.origin)
        hasher.combine(self.size)
    }
}
