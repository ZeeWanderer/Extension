//
//  Hashable2D.swift
//  Extension
//
//  Created by zee wanderer on 12.11.2024.
//


import SwiftExtension
import CoreGraphics

public protocol Hashable2D: Uniform2D, Hashable where Magnitude: Hashable { }

extension Hashable2D where Magnitude: Hashable
{
    @inlinable
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(self.xMagnitude)
        hasher.combine(self.yMagnitude)
    }
}
