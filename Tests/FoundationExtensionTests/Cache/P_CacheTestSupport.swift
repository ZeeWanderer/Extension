//
//  P_CacheTestSupport.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal struct P_CacheInjectedFailure: Error, Equatable, Sendable
{
    internal let storeID: CacheStoreID
    internal let operation: CacheOperation
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal final class P_CacheIntStoreBackend: @unchecked Sendable
{
    internal struct Event: Equatable, Sendable
    {
        internal let operation: CacheOperation
        internal let key: String?
    }

    internal let id: CacheStoreID

    internal let lock = NSLock()
    internal var entries: [String: CacheEntry<Int>]
    internal var failingOperations: Set<CacheOperation>
    internal var events: [Event] = []

    internal init(
        id: CacheStoreID,
        entries: [String: CacheEntry<Int>] = [:],
        failingOperations: Set<CacheOperation> = []
    )
    {
        self.id = id
        self.entries = entries
        self.failingOperations = failingOperations
    }

    internal func makeStore(
        supportsSynchronousAccess: Bool = true
    ) -> CacheStore<String, Int>
    {
        let synchronous = supportsSynchronousAccess
            ? CacheStoreSynchronousOperations<String, Int>(
                retrieve: { key in try self.retrieve(key) },
                store: { entry, key in try self.store(entry, for: key) },
                remove: { key in try self.remove(key) },
                removeAll: { try self.removeAll() }
            )
            : nil

        return CacheStore(
            id: id,
            retrieve: { key in try self.retrieve(key) },
            store: { entry, key in try self.store(entry, for: key) },
            remove: { key in try self.remove(key) },
            removeAll: { try self.removeAll() },
            synchronous: synchronous
        )
    }

    internal func retrieve(_ key: String) throws -> CacheEntry<Int>?
    {
        try lock.withLock {
            events.append(Event(operation: .retrieve, key: key))
            try throwIfConfigured(.retrieve)
            return entries[key]
        }
    }

    internal func store(_ entry: CacheEntry<Int>, for key: String) throws
    {
        try lock.withLock {
            events.append(Event(operation: .store, key: key))
            try throwIfConfigured(.store)
            entries[key] = entry
        }
    }

    internal func remove(_ key: String) throws
    {
        try lock.withLock {
            events.append(Event(operation: .remove, key: key))
            try throwIfConfigured(.remove)
            entries.removeValue(forKey: key)
        }
    }

    internal func removeAll() throws
    {
        try lock.withLock {
            events.append(Event(operation: .removeAll, key: nil))
            try throwIfConfigured(.removeAll)
            entries.removeAll()
        }
    }

    internal func setFailures(_ operations: Set<CacheOperation>)
    {
        lock.withLock {
            failingOperations = operations
        }
    }

    internal func entry(for key: String) -> CacheEntry<Int>?
    {
        lock.withLock { entries[key] }
    }

    internal func eventSnapshot() -> [Event]
    {
        lock.withLock { events }
    }

    internal func resetEvents()
    {
        lock.withLock { events.removeAll() }
    }

    internal func throwIfConfigured(_ operation: CacheOperation) throws
    {
        guard failingOperations.contains(operation) else { return }
        throw P_CacheInjectedFailure(storeID: id, operation: operation)
    }
}

internal struct P_CacheSeededGenerator: RandomNumberGenerator
{
    internal var state: UInt64

    internal init(seed: UInt64)
    {
        state = seed == 0 ? 0x9e3779b97f4a7c15 : seed
    }

    internal mutating func next() -> UInt64
    {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

internal func p_makeCacheTemporaryDirectory(
    named name: String = UUID().uuidString
) throws -> URL
{
    let directory = FileManager.default.temporaryDirectory
        .appending(component: "ExtensionCacheTests", directoryHint: .isDirectory)
        .appending(component: name, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    return directory
}

internal func p_cacheFiles(in directory: URL) throws -> [URL]
{
    guard FileManager.default.fileExists(atPath: directory.path) else
    {
        return []
    }
    return try FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )
    .filter { $0.pathExtension == "cache" }
}

internal func p_cacheAllocatedCapacity(in directory: URL) throws -> UInt64
{
    try p_cacheFiles(in: directory).reduce(into: UInt64(0)) { result, url in
        let values: URLResourceValues
        do
        {
            values = try url.resourceValues(forKeys: [
                .fileSizeKey,
                .fileAllocatedSizeKey,
                .totalFileAllocatedSizeKey,
            ])
        }
        catch CocoaError.fileReadNoSuchFile
        {
            // An automatic maintenance pass can evict a file after directory
            // enumeration but before this observation reads its attributes.
            return
        }
        let capacity = values.totalFileAllocatedSize
            ?? values.fileAllocatedSize
            ?? values.fileSize
            ?? 0
        let (sum, overflow) = result.addingReportingOverflow(
            UInt64(max(0, capacity))
        )
        result = overflow ? .max : sum
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal func p_cacheStoreFailures(
    from error: any Error,
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> [CacheStoreFailure]
{
    guard case let CacheError.storeFailures(failures) = error else
    {
        XCTFail("Expected CacheError.storeFailures, received \(error)", file: file, line: line)
        throw error
    }
    return failures
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal func p_insertSynchronously<Key, Value>(
    _ value: Value,
    into cache: Cache<Key, Value>,
    forKey key: Key,
    route: CacheRoute? = nil
) throws where Key: Hashable & Sendable, Value: Sendable
{
    try cache.insert(value, forKey: key, route: route)
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal func p_valueSynchronously<Key, Value>(
    from cache: Cache<Key, Value>,
    forKey key: Key,
    route: CacheRoute? = nil
) throws -> Value? where Key: Hashable & Sendable, Value: Sendable
{
    try cache.value(forKey: key, route: route)
}
