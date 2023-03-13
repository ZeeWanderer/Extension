//
//  File.swift
//  
//
//  Created by Maksym Kulyk on 13.03.2023.
//

import SwiftUI
import CoreGraphics
import CoreGraphicsExtension

// MARK: - CGPoint
public extension CGPoint
{
    @inlinable
    @inline(__always)
    init(_ point: UnitPoint)
    {
        self.init(x: point.x, y: point.y)
    }
    
    /// Center Anchor bridged from `UnitPoint.center`
    static let center: CGPoint = UnitPoint.center.cgPoint
    static let leading: CGPoint = UnitPoint.leading.cgPoint
    static let trailing: CGPoint = UnitPoint.trailing.cgPoint
    static let top: CGPoint = UnitPoint.top.cgPoint
    static let bottom: CGPoint = UnitPoint.bottom.cgPoint
    static let topLeading: CGPoint = UnitPoint.topLeading.cgPoint
    static let bottomLeading: CGPoint = UnitPoint.bottomLeading.cgPoint
    static let topTrailing: CGPoint = UnitPoint.topTrailing.cgPoint
    static let bottomTrailing: CGPoint = UnitPoint.bottomTrailing.cgPoint
}
