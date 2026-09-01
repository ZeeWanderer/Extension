//
//  P_SparseCacheManifest.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal struct P_SparseCacheManifest: Codable, Sendable
{
    @usableFromInline internal let version: Int
    @usableFromInline internal let capacity: Int
    @usableFromInline internal var ranges: [Range<Int>]
    @usableFromInline internal var generation: Data?
    @usableFromInline internal var metadata: Data?
    @usableFromInline internal let storedAt: Date
    @usableFromInline internal var expirationDate: Date?

    @inlinable
    internal init(
        version: Int,
        capacity: Int,
        ranges: [Range<Int>],
        generation: Data?,
        metadata: Data?,
        storedAt: Date,
        expirationDate: Date?
    )
    {
        self.version = version
        self.capacity = capacity
        self.ranges = ranges
        self.generation = generation
        self.metadata = metadata
        self.storedAt = storedAt
        self.expirationDate = expirationDate
    }

    @inlinable
    internal static func normalizedRanges(
        _ ranges: [Range<Int>]
    ) -> [Range<Int>]
    {
        let ordered = ranges
            .filter { $0.lowerBound >= 0 && !$0.isEmpty }
            .sorted {
                if $0.lowerBound != $1.lowerBound
                {
                    return $0.lowerBound < $1.lowerBound
                }
                return $0.upperBound < $1.upperBound
            }
        guard var current = ordered.first else { return [] }

        var result: [Range<Int>] = []
        for range in ordered.dropFirst()
        {
            if range.lowerBound <= current.upperBound
            {
                current = current.lowerBound..<max(
                    current.upperBound,
                    range.upperBound
                )
            }
            else
            {
                result.append(current)
                current = range
            }
        }
        result.append(current)
        return result
    }

    @inlinable
    internal mutating func insert(_ range: Range<Int>)
    {
        var lowerIndex = 0
        var upperIndex = ranges.count
        while lowerIndex < upperIndex
        {
            let middleIndex = lowerIndex + (upperIndex - lowerIndex) / 2
            if ranges[middleIndex].upperBound < range.lowerBound
            {
                lowerIndex = middleIndex + 1
            }
            else
            {
                upperIndex = middleIndex
            }
        }

        let replacementStart = lowerIndex
        var replacementEnd = replacementStart
        var mergedLowerBound = range.lowerBound
        var mergedUpperBound = range.upperBound
        while replacementEnd < ranges.count,
              ranges[replacementEnd].lowerBound <= mergedUpperBound
        {
            mergedLowerBound = min(
                mergedLowerBound,
                ranges[replacementEnd].lowerBound
            )
            mergedUpperBound = max(
                mergedUpperBound,
                ranges[replacementEnd].upperBound
            )
            replacementEnd += 1
        }
        ranges.replaceSubrange(
            replacementStart..<replacementEnd,
            with: [mergedLowerBound..<mergedUpperBound]
        )
    }

    @inlinable
    internal func contains(_ range: Range<Int>) -> Bool
    {
        ranges.contains {
            $0.lowerBound <= range.lowerBound
                && $0.upperBound >= range.upperBound
        }
    }

    @inlinable
    internal var isValid: Bool
    {
        version == 1
            && capacity > 0
            && Self.normalizedRanges(ranges) == ranges
            && ranges.allSatisfy { $0.upperBound <= capacity }
    }
}
