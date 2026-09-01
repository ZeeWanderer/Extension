//
//  CacheError.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// Configuration and operation failures reported by ``Cache``.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public enum CacheError: Error, @unchecked Sendable
{
    case emptyStoreList
    case duplicateStoreID(CacheStoreID)
    case storeAlreadyAttached(CacheStoreID)
    case unknownStoreID(CacheStoreID)
    case noWriteStores
    case synchronousAccessUnavailable(CacheStoreID)
    case invalidDiskConfiguration(String)
    case invalidDiskEntry
    /// The encoded entry alone cannot fit below the disk store's hard ceiling.
    case diskEntryExceedsMaximumCapacity(
        encodedByteCount: UInt64,
        maximumCapacity: UInt64
    )
    case storeFailures([CacheStoreFailure])
}
