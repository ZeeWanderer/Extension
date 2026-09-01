//
//  CacheCapacityPolicy.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

/// Store-agnostic capacity and least-recently-used eviction rules.
///
/// Capacity is deliberately unitless. A disk store can supply allocated bytes,
/// an in-memory store can supply object cost, and a custom store can supply any
/// consistently measured weight. The policy only selects candidates; the store
/// retains control of enumeration, synchronization, and removal.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheCapacityPolicy: Hashable, Sendable
{
    /// A store-owned entry eligible for capacity eviction.
    public struct Candidate<ID: Sendable>: Sendable
    {
        public let id: ID
        public let capacity: UInt64
        public let lastAccessDate: Date

        @inlinable
        public init(
            id: ID,
            capacity: UInt64,
            lastAccessDate: Date
        )
        {
            self.id = id
            self.capacity = capacity
            self.lastAccessDate = lastAccessDate
        }
    }

    /// A deterministic capacity decision for a store to apply atomically.
    public struct EvictionPlan<ID: Sendable>: Sendable
    {
        public let evictions: [Candidate<ID>]
        public let projectedCapacity: UInt64
        public let protectedEntryCount: Int
        public let protectedCapacity: UInt64
        public let didExceedMaximumCapacity: Bool

        @inlinable
        public init(
            evictions: [Candidate<ID>],
            projectedCapacity: UInt64,
            protectedEntryCount: Int,
            protectedCapacity: UInt64,
            didExceedMaximumCapacity: Bool
        )
        {
            self.evictions = evictions
            self.projectedCapacity = projectedCapacity
            self.protectedEntryCount = max(0, protectedEntryCount)
            self.protectedCapacity = protectedCapacity
            self.didExceedMaximumCapacity = didExceedMaximumCapacity
        }
    }

    /// Capacity at which maintenance begins, or `nil` when unlimited.
    public let preferredCapacity: UInt64?
    /// Capacity maintenance attempts to reach after it begins.
    public let trimToCapacity: UInt64?
    /// Capacity above which recent-use protection is ignored.
    public let maximumCapacity: UInt64?
    /// How long an accessed entry is protected below the hard ceiling.
    public let recentAccessProtectionInterval: TimeInterval

    /// Creates a normalized bounded or unlimited policy.
    ///
    /// Passing `nil` for `preferredCapacity` creates an unlimited policy. For a
    /// bounded policy, the trim target is clamped to the preferred capacity and
    /// the maximum is raised to at least the preferred capacity.
    @inlinable
    public init(
        preferredCapacity: UInt64?,
        trimToCapacity: UInt64? = nil,
        maximumCapacity: UInt64? = nil,
        recentAccessProtectionInterval: TimeInterval = 0
    )
    {
        guard let preferredCapacity else
        {
            self.preferredCapacity = nil
            self.trimToCapacity = nil
            self.maximumCapacity = nil
            self.recentAccessProtectionInterval = 0
            return
        }

        self.preferredCapacity = preferredCapacity
        self.trimToCapacity = min(
            trimToCapacity ?? preferredCapacity,
            preferredCapacity
        )
        self.maximumCapacity = max(
            maximumCapacity ?? preferredCapacity,
            preferredCapacity
        )
        self.recentAccessProtectionInterval =
            recentAccessProtectionInterval.isNaN
                ? 0
                : max(0, recentAccessProtectionInterval)
    }

    /// A policy that never performs capacity eviction.
    public static let unlimited = Self(preferredCapacity: nil)

    /// Creates a strict limit without recent-use protection.
    @inlinable
    public static func hard(
        maximumCapacity: UInt64,
        trimToCapacity: UInt64? = nil
    ) -> Self
    {
        Self(
            preferredCapacity: maximumCapacity,
            trimToCapacity: trimToCapacity,
            maximumCapacity: maximumCapacity
        )
    }

    /// Creates a soft target with an unconditional hard ceiling.
    @inlinable
    public static func soft(
        preferredCapacity: UInt64,
        trimToCapacity: UInt64? = nil,
        maximumCapacity: UInt64,
        recentAccessProtectionInterval: TimeInterval
    ) -> Self
    {
        Self(
            preferredCapacity: preferredCapacity,
            trimToCapacity: trimToCapacity,
            maximumCapacity: maximumCapacity,
            recentAccessProtectionInterval:
                recentAccessProtectionInterval
        )
    }

    @inlinable
    public var isUnlimited: Bool { preferredCapacity == nil }

    /// Returns whether one entry can ever fit below the hard ceiling.
    @inlinable
    public func allowsEntry(capacity: UInt64) -> Bool
    {
        maximumCapacity.map { capacity <= $0 } ?? true
    }

    /// Selects least-recently-used candidates until the trim target is met.
    ///
    /// Below the maximum capacity, entries accessed inside
    /// ``recentAccessProtectionInterval`` are skipped. The protection is
    /// automatically ignored when the hard ceiling is exceeded. A caller can
    /// also ignore it explicitly for a user-requested aggressive pass.
    /// Candidates with equal access dates retain their input order.
    @inlinable
    public func evictionPlan<ID: Sendable>(
        currentCapacity: UInt64,
        candidates: [Candidate<ID>],
        at date: Date = .now,
        allowsProtectedEviction: Bool = false
    ) -> EvictionPlan<ID>
    {
        guard let preferredCapacity,
              let trimToCapacity,
              let maximumCapacity,
              currentCapacity > preferredCapacity else
        {
            return EvictionPlan(
                evictions: [],
                projectedCapacity: currentCapacity,
                protectedEntryCount: 0,
                protectedCapacity: 0,
                didExceedMaximumCapacity: false
            )
        }

        let didExceedMaximumCapacity = currentCapacity > maximumCapacity
        let ignoresProtection = allowsProtectedEviction
            || didExceedMaximumCapacity
            || recentAccessProtectionInterval == 0
        let ordered = candidates.enumerated().sorted { lhs, rhs in
            if lhs.element.lastAccessDate != rhs.element.lastAccessDate
            {
                return lhs.element.lastAccessDate
                    < rhs.element.lastAccessDate
            }
            return lhs.offset < rhs.offset
        }

        var projectedCapacity = currentCapacity
        var evictions: [Candidate<ID>] = []
        var protectedEntryCount = 0
        var protectedCapacity: UInt64 = 0
        for candidate in ordered where projectedCapacity > trimToCapacity
        {
            guard candidate.element.capacity > 0 else { continue }
            if !ignoresProtection,
               date.timeIntervalSince(candidate.element.lastAccessDate)
                < recentAccessProtectionInterval
            {
                protectedEntryCount += 1
                let (sum, overflow) = protectedCapacity.addingReportingOverflow(
                    candidate.element.capacity
                )
                protectedCapacity = overflow ? .max : sum
                continue
            }

            evictions.append(candidate.element)
            projectedCapacity = projectedCapacity >= candidate.element.capacity
                ? projectedCapacity - candidate.element.capacity
                : 0
        }

        return EvictionPlan(
            evictions: evictions,
            projectedCapacity: projectedCapacity,
            protectedEntryCount: protectedEntryCount,
            protectedCapacity: protectedCapacity,
            didExceedMaximumCapacity: didExceedMaximumCapacity
        )
    }
}
