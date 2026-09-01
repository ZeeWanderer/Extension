//
//  MemoryCacheConfiguration.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// Configuration for an `NSCache`-backed cache store.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct MemoryCacheConfiguration: Hashable, Sendable
{
    /// The diagnostic name assigned to the underlying `NSCache`.
    public var name: String
    /// The maximum entry count, or zero for no count limit.
    public var countLimit: Int
    /// The maximum total entry cost, or zero for no cost limit.
    public var totalCostLimit: Int
    /// Whether entries whose content is discarded should be evicted.
    public var evictsObjectsWithDiscardedContent: Bool

    @inlinable
    public init(
        name: String = "memory",
        countLimit: Int = 0,
        totalCostLimit: Int = 0,
        evictsObjectsWithDiscardedContent: Bool = false
    )
    {
        self.name = name
        self.countLimit = max(0, countLimit)
        self.totalCostLimit = max(0, totalCostLimit)
        self.evictsObjectsWithDiscardedContent = evictsObjectsWithDiscardedContent
    }
}
