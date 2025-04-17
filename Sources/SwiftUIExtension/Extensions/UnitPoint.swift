//
//  UnitPoint.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//

import SwiftUI

public extension UnitPoint
{
    @inlinable
    @inline(__always)
    var cgPoint: CGPoint
    {
        return .init(x: self.x, y: self.y)
    }
}
