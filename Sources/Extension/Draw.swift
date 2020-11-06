//
//  Draw.swift
//  Extension
//
//  Created by Maksym Kulyk on 11/6/20.
//  Copyright © 2020 max. All rights reserved.
//

import UIKit

// overrides default print function in release build
#if DEBUG
public func debug_rect_stroke(_ rect: CGRect, color: CGColor = UIColor.white.cgColor)
{
    if let ctx = UIGraphicsGetCurrentContext()
    {
        ctx.saveGState()
        ctx.setStrokeColor(color)
        let b_rect = UIBezierPath(rect: rect)
        b_rect.stroke()
        ctx.restoreGState()
    }
}
#else
public func debug_rect_stroke(_ rect: CGRect, color: CGColor = UIColor.white.cgColor)
{
}
#endif
