//
//  SparseCacheConfiguration.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

/// Configuration for a byte-range sparse cache namespace.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct SparseCacheConfiguration: Sendable
{
    /// The namespace directory name inside ``DiskCacheStorage``.
    public var name: String
    /// Delay used to coalesce manifest updates after range writes.
    public var manifestFlushDelay: Duration
    /// Whether initialization fails when the selected volume cannot confirm
    /// native sparse-file support.
    ///
    /// Disabling this can cause a large logical capacity to consume its complete
    /// size immediately on a nonsparse volume.
    public var requiresSparseFileSupport: Bool

    @inlinable
    public init(
        name: String = "sparse",
        manifestFlushDelay: Duration = .milliseconds(250),
        requiresSparseFileSupport: Bool = true
    )
    {
        self.name = name
        self.manifestFlushDelay = max(.zero, manifestFlushDelay)
        self.requiresSparseFileSupport = requiresSparseFileSupport
    }
}
