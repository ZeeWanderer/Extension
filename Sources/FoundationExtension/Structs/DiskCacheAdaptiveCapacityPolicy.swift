//
//  DiskCacheAdaptiveCapacityPolicy.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

/// Resolves one stable disk-cache budget from available volume capacity.
///
/// Resolution happens once when ``DiskCacheStorage`` is created. The resulting
/// budget does not shrink as the cache consumes space, avoiding capacity and
/// eviction feedback loops during the lifetime of the storage object.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct DiskCacheAdaptiveCapacityPolicy: Hashable, Sendable
{
    /// Selects the volume-capacity estimate appropriate for cached content.
    public enum Usage: Hashable, Sendable
    {
        /// Replaceable or predictive content that is not immediately required.
        case opportunistic
        /// Content required for an explicit user operation already in progress.
        case important
    }

    /// Which system-provided available-capacity estimate is queried.
    public let usage: Usage
    /// Fraction of available capacity, including this cache's current allocation.
    public let availableCapacityFraction: Double
    /// Absolute upper bound for the resolved hard ceiling.
    public let maximumCapacity: UInt64
    /// Fraction of the hard ceiling used as the eviction high watermark.
    public let preferredCapacityFraction: Double
    /// Fraction of the preferred capacity used as the post-eviction target.
    public let trimToCapacityFraction: Double
    /// How long recently used entries remain protected below the hard ceiling.
    public let recentAccessProtectionInterval: TimeInterval

    /// Creates a normalized adaptive policy.
    ///
    /// The defaults devote at most ten percent of currently reclaimable space
    /// to this cache, cap its emergency ceiling at 1 GiB, begin eviction at two
    /// thirds of that ceiling, and trim to three quarters of the high watermark.
    @inlinable
    public init(
        usage: Usage = .opportunistic,
        availableCapacityFraction: Double = 0.1,
        maximumCapacity: UInt64 = 1024 * 1024 * 1024,
        preferredCapacityFraction: Double = 2.0 / 3.0,
        trimToCapacityFraction: Double = 0.75,
        recentAccessProtectionInterval: TimeInterval = 10 * 60
    )
    {
        self.usage = usage
        self.availableCapacityFraction = Self.p_normalizedFraction(
            availableCapacityFraction,
            fallback: 0.1
        )
        self.maximumCapacity = maximumCapacity
        self.preferredCapacityFraction = Self.p_normalizedFraction(
            preferredCapacityFraction,
            fallback: 2.0 / 3.0
        )
        self.trimToCapacityFraction = Self.p_normalizedFraction(
            trimToCapacityFraction,
            fallback: 0.75
        )
        self.recentAccessProtectionInterval =
            recentAccessProtectionInterval.isNaN
                ? 0
                : max(0, recentAccessProtectionInterval)
    }

    /// Resolves the fixed policy used for one storage lifetime.
    ///
    /// `availableCapacity` is the system estimate before reclaiming this cache.
    /// Adding `existingCacheCapacity` prevents an existing cache from reducing
    /// its own next-launch budget merely because its files occupy disk space.
    @inlinable
    public func capacityPolicy(
        availableCapacity: UInt64,
        existingCacheCapacity: UInt64
    ) -> CacheCapacityPolicy
    {
        let reclaimableCapacity = Self.p_saturatingSum(
            availableCapacity,
            existingCacheCapacity
        )
        let proportionalMaximum = Self.p_scaled(
            reclaimableCapacity,
            by: availableCapacityFraction
        )
        let resolvedMaximum = min(maximumCapacity, proportionalMaximum)
        let preferredCapacity = Self.p_scaled(
            resolvedMaximum,
            by: preferredCapacityFraction
        )
        let trimToCapacity = Self.p_scaled(
            preferredCapacity,
            by: trimToCapacityFraction
        )
        return .soft(
            preferredCapacity: preferredCapacity,
            trimToCapacity: trimToCapacity,
            maximumCapacity: resolvedMaximum,
            recentAccessProtectionInterval:
                recentAccessProtectionInterval
        )
    }

    @inlinable
    internal static func p_normalizedFraction(
        _ value: Double,
        fallback: Double
    ) -> Double
    {
        value.isFinite ? min(1, max(0, value)) : fallback
    }

    @inlinable
    internal static func p_scaled(
        _ capacity: UInt64,
        by fraction: Double
    ) -> UInt64
    {
        guard capacity > 0, fraction > 0 else { return 0 }
        if fraction >= 1 { return capacity }
        let scaled = Double(capacity) * fraction
        guard scaled < Double(UInt64.max) else { return capacity }
        return UInt64(scaled.rounded(.down))
    }

    @inlinable
    internal static func p_saturatingSum(
        _ lhs: UInt64,
        _ rhs: UInt64
    ) -> UInt64
    {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? .max : sum
    }
}
