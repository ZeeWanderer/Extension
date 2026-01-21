//
//  Range.swift
//
//  Created by zeewanderer on 21.01.2026.
//

public extension Range where Bound: Comparable
{
    /// Returns the overlap between `self` and `other`, or `nil` if they don't overlap.
    @inlinable
    @inline(__always)
    func intersection(_ other: Self) -> Self?
    {
        guard self.overlaps(other) else { return nil }
        return Swift.max(lowerBound, other.lowerBound)..<Swift.min(upperBound, other.upperBound)
    }
}
