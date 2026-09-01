//
//  CGSize.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

public extension CGSize
{
    @inlinable
    @inline(__always)
    init(side: CGFloat)
    {
        self.init(width: side, height: side)
    }

    /// `width * height`
    @_transparent
    var square: CGFloat
    {
        return self.height * self.width
    }

    /// Center point of the rectange area defined by `CGSize`
    @_transparent
    var center: CGPoint
    {
        return .init(x: self.width / 2.0, y: self.height / 2.0)
    }

    @_transparent
    var diagonal: CGFloat
    {
        hypot(self.width, self.height)
    }
}
