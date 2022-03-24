//
//  Math.swift
//  
//
//  Created by Maksym Kulyk on 18.03.2022.
//

import Foundation

@inline(__always)
public func clamp<T>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable
{
    return min(max(value, minValue), maxValue)
}

@inline(__always)
public func clamp<T>(_ value: T, to limits: ClosedRange<T>) -> T where T: Comparable
{
    return min(max(value, limits.lowerBound), limits.upperBound)
}

@inline(__always)
public func lerp<T>(_ value: T, min: T, max: T) -> T where T: Numeric
{
    return min + (value * (max - min))
}
