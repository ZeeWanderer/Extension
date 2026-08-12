//
//  Math.swift
//  
//
//  Created by zeewanderer on 19.04.2022.
//

import SwiftExtension
import RealModule
import CoreGraphics

/// Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately.
/// See: `SwiftExtension/lerp(_:min:max:)`
@_transparent
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
@_transparent
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
@_transparent
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
@_transparent
public func lerp<A: Numeric2D, B: Numeric2D>(_ parameter: A, min: B, max: B) -> B
where A.Magnitude: Real, B.Magnitude: Real, A.Magnitude == B.Magnitude
{
    let x = lerp(parameter.xMagnitude, min: min.xMagnitude, max: max.xMagnitude)
    let y = lerp(parameter.yMagnitude, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately with corresponding `parameter` coordinate as parameter
/// See: `SwiftExtension/lerp(_:min:max:)`
@_transparent
public func lerp(_ parameter: CGFloat, min: CGRect, max: CGRect) -> CGRect
{
    let origin = lerp(parameter, min: min.origin, max: max.origin)
    let size = lerp(parameter, min: min.size, max: max.size)
    return .init(origin: origin, size: size)
}

/// Inverse Linear interpolate value in `[min,max]` for `parameter`.
/// Each axis is intepolated separately.
/// See: `SwiftExtension/ilerp(_:min:max:)`
@_transparent
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
@_transparent
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
@_transparent
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
@_transparent
public func ilerp<A: Numeric2D, B: Numeric2D>(_ parameter: A, min: B, max: B) -> B
where A.Magnitude: Real, B.Magnitude: Real, A.Magnitude == B.Magnitude
{
    let x = ilerp(parameter.xMagnitude, min: min.xMagnitude, max: max.xMagnitude)
    let y = ilerp(parameter.yMagnitude, min: min.yMagnitude, max: max.yMagnitude)
    return .init(xMagnitude: x, yMagnitude: y)
}

/// Clamps `xMagnitude` to provided range
@_transparent
public func clamp<T, M>(_ value: T, x range: ClosedRange<M>) -> T where T: Numeric2D, T.Magnitude == M
{
    return .init(xMagnitude: value.xMagnitude.clamped(to: range), yMagnitude: value.yMagnitude)
}

/// Clamps `yMagnitude` to provided range
@_transparent
public func clamp<T, M>(_ value: T, y range: ClosedRange<M>) -> T where T: Numeric2D, T.Magnitude == M
{
    return .init(xMagnitude: value.xMagnitude, yMagnitude: value.yMagnitude.clamped(to: range))
}

/// Clamps `xMagnitude` and `yMagnitude` to provided range
@_transparent
public func clamp<T, M>(_ value: T, to range: ClosedRange<M>) -> T where T: Numeric2D, T.Magnitude == M
{
    return .init(xMagnitude: value.xMagnitude.clamped(to: range), yMagnitude: value.yMagnitude.clamped(to: range))
}

/// Clamps `xMagnitude` and `yMagnitude` to provided ranges
@_transparent
public func clamp<T, M>(_ value: T, x rangeX: ClosedRange<M>, y rangeY: ClosedRange<M>) -> T where T: Numeric2D, T.Magnitude == M
{
    return .init(xMagnitude: value.xMagnitude.clamped(to: rangeX), yMagnitude: value.yMagnitude.clamped(to: rangeY))
}

// MARK: - CGRect
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

// MARK: - Numeric2D public functions

@_transparent
public func min<T>(_ lhs: T, _ rhs: T) -> T where T: Numeric2D
{
    return T(xMagnitude: min(lhs.xMagnitude, rhs.xMagnitude), yMagnitude: min(lhs.yMagnitude, rhs.yMagnitude))
}

@_transparent
public func min<T>(_ scalar: T.Magnitude, _ rhs: T) -> T where T: Numeric2D
{
    return T(xMagnitude: min(scalar, rhs.xMagnitude), yMagnitude: min(scalar, rhs.yMagnitude))
}

@_transparent
public func max<T>(_ lhs: T, _ rhs: T) -> T where T: Numeric2D
{
    return T(xMagnitude: max(lhs.xMagnitude, rhs.xMagnitude), yMagnitude: max(lhs.yMagnitude, rhs.yMagnitude))
}

@_transparent
public func max<T>(_ scalar: T.Magnitude, _ rhs: T) -> T where T: Numeric2D
{
    return T(xMagnitude: max(scalar, rhs.xMagnitude), yMagnitude: max(scalar, rhs.yMagnitude))
}
