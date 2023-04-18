//
//  Math.swift
//  
//
//  Created by Maksym Kulyk on 19.04.2022.
//


import SwiftExtension
import CoreGraphics

/// Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately.
/// See: `SwiftExtension/lerp(_:min:max:)`
@inlinable
@inline(__always)
public func lerp<A: Real, B: Numeric2D, C: Numeric2D, R: Numeric2D>(_ parameter: A, min: B, max: C) -> R
where B.Magnitude: Real, C.Magnitude: Real, R.Magnitude: Real,
      C.Magnitude == B.Magnitude, C.Magnitude == R.Magnitude, C.Magnitude == A
{
    let x = lerp(parameter, min: min.xMagnitude, max: max.xMagnitude)
    let y = lerp(parameter, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately.
/// See: `SwiftExtension/lerp(_:min:max:)`
@inlinable
@inline(__always)
public func lerp<A: Real, B: Numeric2D>(_ parameter: A, min: B, max: B) -> B
where B.Magnitude: Real, B.Magnitude == A
{
    let x = lerp(parameter, min: min.xMagnitude, max: max.xMagnitude)
    let y = lerp(parameter, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately with corresponding `parameter` coordinate as parameter
/// See: `SwiftExtension/lerp(_:min:max:)`
@inlinable
@inline(__always)
public func lerp<A: Numeric2D, B: Numeric2D, C: Numeric2D, R: Numeric2D>(_ parameter: A, min: B, max: C) -> R
where A.Magnitude: Real, B.Magnitude: Real, C.Magnitude: Real, R.Magnitude: Real,
      A.Magnitude == B.Magnitude, A.Magnitude == C.Magnitude, A.Magnitude == R.Magnitude
{
    let x = lerp(parameter.xMagnitude, min: min.xMagnitude, max: max.xMagnitude)
    let y = lerp(parameter.yMagnitude, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately with corresponding `parameter` coordinate as parameter
/// See: `SwiftExtension/lerp(_:min:max:)`
@inlinable
@inline(__always)
public func lerp<A: Numeric2D, B: Numeric2D>(_ parameter: A, min: B, max: B) -> B
where A.Magnitude: Real, B.Magnitude: Real, A.Magnitude == B.Magnitude
{
    let x = lerp(parameter.xMagnitude, min: min.xMagnitude, max: max.xMagnitude)
    let y = lerp(parameter.yMagnitude, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// Inverse Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately.
/// See: `SwiftExtension/ilerp(_:min:max:)`
@inlinable
@inline(__always)
public func ilerp<A: Real, B: Numeric2D, C: Numeric2D, R: Numeric2D>(_ parameter: A, min: B, max: C) -> R
where B.Magnitude: Real, C.Magnitude: Real, R.Magnitude: Real,
      C.Magnitude == B.Magnitude, C.Magnitude == R.Magnitude, C.Magnitude == A
{
    let x = ilerp(parameter, min: min.xMagnitude, max: max.xMagnitude)
    let y = ilerp(parameter, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// Inverse Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately.
/// See: `SwiftExtension/ilerp(_:min:max:)`
@inlinable
@inline(__always)
public func ilerp<A: Real, B: Numeric2D>(_ parameter: A, min: B, max: B) -> B
where B.Magnitude: Real, B.Magnitude == A
{
    let x = ilerp(parameter, min: min.xMagnitude, max: max.xMagnitude)
    let y = ilerp(parameter, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// Inverse Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately with corresponding `parameter` coordinate as parameter
/// See: `SwiftExtension/ilerp(_:min:max:)`
@inlinable
@inline(__always)
public func ilerp<A: Numeric2D, B: Numeric2D, C: Numeric2D, R: Numeric2D>(_ parameter: A, min: B, max: C) -> R
where A.Magnitude: Real, B.Magnitude: Real, C.Magnitude: Real, R.Magnitude: Real,
      A.Magnitude == B.Magnitude, A.Magnitude == C.Magnitude, A.Magnitude == R.Magnitude
{
    let x = ilerp(parameter.xMagnitude, min: min.xMagnitude, max: max.xMagnitude)
    let y = ilerp(parameter.yMagnitude, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// Inverse Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately with corresponding `parameter` coordinate as parameter
/// See: `SwiftExtension/ilerp(_:min:max:)`
@inlinable
@inline(__always)
public func ilerp<A: Numeric2D, B: Numeric2D>(_ parameter: A, min: B, max: B) -> B
where A.Magnitude: Real, B.Magnitude: Real, A.Magnitude == B.Magnitude
{
    let x = ilerp(parameter.xMagnitude, min: min.xMagnitude, max: max.xMagnitude)
    let y = ilerp(parameter.yMagnitude, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// All rectangles are standardized prior to calculating the union.
/// If either of the rectangles is a null rectangle, it is ignored. If all rectangles are null, a null rectangle is returned.
/// Otherwise a rectangle that completely contains the source rectangles is returned.
@inlinable
public func union(_ rects: [CGRect]) -> CGRect
{
    let bounding_rect = rects.reduce(CGRect.null) { (result, element) in
        return result.union(element)
    }
    
    return bounding_rect
}

// MARK: - CGVector
/// Clamps `dx` to provided range
@inlinable
@inline(__always)
public func clamp(_ value: CGVector, dx range: ClosedRange<CGFloat>) -> CGVector
{
    return .init(dx: value.dx.clamped(to: range), dy: value.dy)
}

/// Clamps `dy` to provided range
@inlinable
@inline(__always)
public func clamp(_ value: CGVector, dy range: ClosedRange<CGFloat>) -> CGVector
{
    return .init(dx: value.dx, dy: value.dy.clamped(to: range))
}

/// Clamps `dx` and `dy` to provided ranges
@inlinable
@inline(__always)
public func clamp(_ value: CGVector, dx rangeDx: ClosedRange<CGFloat>, dy rangeDy: ClosedRange<CGFloat>) -> CGVector
{
    return .init(dx: value.dx.clamped(to: rangeDx), dy: value.dy.clamped(to: rangeDy))
}

/// Clamps `dx` and `dy` to provided range
@inlinable
@inline(__always)
public func clamp(_ value: CGVector, to range: ClosedRange<CGFloat>) -> CGVector
{
    return .init(dx: value.dx.clamped(to: range), dy: value.dy.clamped(to: range))
}

// MARK: - CGPoint
/// Clamps `x` to provided range
@inlinable
@inline(__always)
public func clamp(_ value: CGPoint, x range: ClosedRange<CGFloat>) -> CGPoint
{
    return .init(x: value.x.clamped(to: range), y: value.y)
}

/// Clamps `y` to provided range
@inlinable
@inline(__always)
public func clamp(_ value: CGPoint, y range: ClosedRange<CGFloat>) -> CGPoint
{
    return .init(x: value.x, y: value.y.clamped(to: range))
}

/// Clamps `x` and `y` to provided ranges
@inlinable
@inline(__always)
public func clamp(_ value: CGPoint, x rangeX: ClosedRange<CGFloat>, y rangeY: ClosedRange<CGFloat>) -> CGPoint
{
    return .init(x: value.x.clamped(to: rangeX), y: value.y.clamped(to: rangeY))
}

/// Clamps `x` and `y` to provided range
@inlinable
@inline(__always)
public func clamp(_ value: CGPoint, to range: ClosedRange<CGFloat>) -> CGPoint
{
    return .init(x: value.x.clamped(to: range), y: value.y.clamped(to: range))
}

// MARK: - CGSize
/// Clamps `width` to provided range
@inlinable
@inline(__always)
public func clamp(_ value: CGSize, width range: ClosedRange<CGFloat>) -> CGSize
{
    return .init(width: value.width.clamped(to: range), height: value.height)
}

/// Clamps `height` to provided range
@inlinable
@inline(__always)
public func clamp(_ value: CGSize, height range: ClosedRange<CGFloat>) -> CGSize
{
    return .init(width: value.width, height: value.height.clamped(to: range))
}

/// Clamps `width` and `height` to provided ranges
@inlinable
@inline(__always)
public func clamp(_ value: CGSize, width rangeWidth: ClosedRange<CGFloat>, height rangeHeight: ClosedRange<CGFloat>) -> CGSize
{
    return .init(width: value.width.clamped(to: rangeWidth), height: value.height.clamped(to: rangeHeight))
}

/// Clamps `width` and `height` to provided range
@inlinable
@inline(__always)
public func clamp(_ value: CGSize, to range: ClosedRange<CGFloat>) -> CGSize
{
    return .init(width: value.width.clamped(to: range), height: value.height.clamped(to: range))
}
