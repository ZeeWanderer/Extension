//
//  Math.swift
//  
//
//  Created by Maksym Kulyk on 19.04.2022.
//

import CoreGraphics
import FoundationExtension

/// Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately.
/// See: ``FoundationExtension/lerp(_:min:max:)``
public func lerp(_ parameter: CGFloat, min: CGPoint, max: CGPoint) -> CGPoint
{
    let x = lerp(parameter, min: min.x, max: max.x)
    let y = lerp(parameter, min: min.y, max: max.y)
    return CGPoint(x: x, y: y)
}

/// Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately with corresponding `parameter` coordinate as parameter
/// See: ``FoundationExtension/lerp(_:min:max:)``
public func lerp(_ parameter: CGPoint, min: CGPoint, max: CGPoint) -> CGPoint
{
    let x = lerp(parameter.x, min: min.x, max: max.x)
    let y = lerp(parameter.y, min: min.y, max: max.y)
    return CGPoint(x: x, y: y)
}