//
//  SparseCacheSnapshot.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

/// An immutable view of one sparse cache entry.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct SparseCacheSnapshot: Equatable, Sendable
{
    public let capacity: Int
    public let ranges: [Range<Int>]
    /// A caller-defined resource generation used to invalidate old bytes.
    public let generation: Data?
    /// Opaque caller metadata stored alongside the range index.
    public let metadata: Data?
    public let storedAt: Date
    public let expirationDate: Date?

    @inlinable
    internal init(
        capacity: Int,
        ranges: [Range<Int>],
        generation: Data?,
        metadata: Data?,
        storedAt: Date,
        expirationDate: Date?
    )
    {
        self.capacity = capacity
        self.ranges = ranges
        self.generation = generation
        self.metadata = metadata
        self.storedAt = storedAt
        self.expirationDate = expirationDate
    }

    @inlinable
    internal init(_ manifest: P_SparseCacheManifest)
    {
        self.init(
            capacity: manifest.capacity,
            ranges: manifest.ranges,
            generation: manifest.generation,
            metadata: manifest.metadata,
            storedAt: manifest.storedAt,
            expirationDate: manifest.expirationDate
        )
    }

    /// The number of unique bytes represented by ``ranges``.
    @inlinable
    public var availableByteCount: Int
    {
        ranges.reduce(into: 0) { $0 += $1.count }
    }

    @inlinable
    public var isComplete: Bool
    {
        capacity > 0 && contains(0..<capacity)
    }

    /// Returns whether every byte in a range is available.
    @inlinable
    public func contains(_ range: Range<Int>) -> Bool
    {
        ranges.contains {
            $0.lowerBound <= range.lowerBound
                && $0.upperBound >= range.upperBound
        }
    }

    /// Returns cached bytes that can be read contiguously from a position.
    @inlinable
    public func contiguousRange(
        in requestedRange: Range<Int>,
        from position: Int,
        maximumLength: Int? = nil
    ) -> Range<Int>?
    {
        guard requestedRange.contains(position),
              maximumLength.map({ $0 > 0 }) != false,
              let available = ranges.first(where: { $0.contains(position) }) else { return nil }

        var upperBound = min(available.upperBound, requestedRange.upperBound)
        if let maximumLength, maximumLength > 0
        {
            let (limited, overflow) = position.addingReportingOverflow(
                maximumLength
            )
            if !overflow { upperBound = min(upperBound, limited) }
        }
        return position < upperBound ? position..<upperBound : nil
    }

    /// Returns normalized gaps in a requested range.
    @inlinable
    public func missingRanges(
        in requestedRange: Range<Int>
    ) -> [Range<Int>]
    {
        guard !requestedRange.isEmpty else { return [] }
        var result: [Range<Int>] = []
        var position = requestedRange.lowerBound
        for range in ranges
        {
            if range.upperBound <= position { continue }
            if range.lowerBound >= requestedRange.upperBound { break }
            if position < range.lowerBound
            {
                result.append(
                    position..<min(requestedRange.upperBound, range.lowerBound)
                )
            }
            position = max(position, range.upperBound)
            if position >= requestedRange.upperBound { break }
        }
        if position < requestedRange.upperBound
        {
            result.append(position..<requestedRange.upperBound)
        }
        return result
    }
}
