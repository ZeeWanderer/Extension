//
//  Angle.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//

import SwiftUI

public extension Angle
{
    @inlinable
    @inline(__always) var quarter: Int
    {
        Int((abs(self.degrees).truncatingRemainder(dividingBy: 360)) / 90.0)
    }
}
