//
//  Debug.swift
//  
//
//  Created by Maksym Kulyk on 05.04.2022.
//

import UIKit
import FoundationExtension

/// Strokes specified rect in current CGContext if it can get one
@available(*, deprecated, renamed: "debug_rect(_:color:)")
public func debugRect(_ rect: CGRect, color: CGColor = UIColor.white.cgColor)
{
    debug_action {
        if let ctx = UIGraphicsGetCurrentContext()
        {
            ctx.saveGState()
            ctx.setStrokeColor(color)
            let b_rect = UIBezierPath(rect: rect)
            b_rect.stroke()
            ctx.restoreGState()
        }
    }
}

/// Strokes specified rect in current CGContext if it can get one
public func debug_rect(_ rect: CGRect, color: CGColor = UIColor.white.cgColor)
{
    debug_action {
        if let ctx = UIGraphicsGetCurrentContext()
        {
            ctx.saveGState()
            ctx.setStrokeColor(color)
            let b_rect = UIBezierPath(rect: rect)
            b_rect.stroke()
            ctx.restoreGState()
        }
    }
}
