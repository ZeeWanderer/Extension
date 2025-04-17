//
//  GeometryProxy.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//

import SwiftUI

public extension GeometryProxy
{
    @inlinable
    @inline(__always) func scale(for refernce: CGSize) -> CGPoint
    {
        return CGPoint(self.size ./ refernce)
    }
}
