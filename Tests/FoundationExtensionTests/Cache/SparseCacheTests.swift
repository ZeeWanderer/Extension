//
//  SparseCacheTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class SparseCacheTests: XCTestCase
{
    func testCustomStorageLocationIsSharedByObjectAndSparseCaches() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let storage = try DiskCacheStorage(
            name: "shared",
            location: .custom(root),
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let objectCache = try Cache(stores: [
            try CacheStore<String, Data>.disk(storage: storage),
        ])
        let sparseCache = try SparseCache<String>(storage: storage)

        try await objectCache.insert(Data("object".utf8), forKey: "object")
        _ = try await sparseCache.prepare(
            capacity: 64,
            generation: Data("v1".utf8),
            metadata: Data("metadata".utf8),
            forKey: "video"
        )
        _ = try await sparseCache.insert(
            Data("range".utf8),
            at: 8,
            forKey: "video"
        )
        try await sparseCache.synchronize(forKey: "video")

        XCTAssertEqual(
            storage.directoryURL,
            root.appending(component: "shared", directoryHint: .isDirectory)
        )
        let object = try await objectCache.value(forKey: "object")
        let range = try await sparseCache.data(in: 8..<13, forKey: "video")
        XCTAssertEqual(object, Data("object".utf8))
        XCTAssertEqual(range, Data("range".utf8))
    }

    func testPrepareInsertReadAndRangeMath() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)

        let prepared = try await cache.prepare(
            capacity: 32,
            generation: Data("v1".utf8),
            metadata: Data("meta".utf8),
            forKey: "video"
        )
        XCTAssertTrue(prepared.ranges.isEmpty)

        _ = try await cache.insert(Data([1, 2, 3, 4]), at: 4, forKey: "video")
        let loadedSnapshot = try await cache.snapshot(forKey: "video")
        let snapshot = try XCTUnwrap(loadedSnapshot)

        XCTAssertEqual(snapshot.capacity, 32)
        XCTAssertEqual(snapshot.generation, Data("v1".utf8))
        XCTAssertEqual(snapshot.metadata, Data("meta".utf8))
        XCTAssertEqual(snapshot.ranges, [4..<8])
        XCTAssertEqual(snapshot.availableByteCount, 4)
        XCTAssertTrue(snapshot.contains(5..<7))
        XCTAssertEqual(snapshot.missingRanges(in: 2..<10), [2..<4, 8..<10])
        XCTAssertEqual(
            snapshot.contiguousRange(in: 2..<10, from: 5, maximumLength: 2),
            5..<7
        )
        let storedData = try await cache.data(in: 4..<8, forKey: "video")
        let incompleteData = try await cache.data(in: 3..<8, forKey: "video")
        XCTAssertEqual(storedData, Data([1, 2, 3, 4]))
        XCTAssertNil(incompleteData)
    }

    func testGenerationChangeResetsRangesEvenWhenCapacityMatches() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)

        _ = try await cache.prepare(
            capacity: 32,
            generation: Data("v1".utf8),
            forKey: "video"
        )
        _ = try await cache.insert(Data([1, 2, 3]), at: 0, forKey: "video")

        let reset = try await cache.prepare(
            capacity: 32,
            generation: Data("v2".utf8),
            forKey: "video"
        )

        XCTAssertTrue(reset.ranges.isEmpty)
        XCTAssertEqual(reset.generation, Data("v2".utf8))
        let oldData = try await cache.data(in: 0..<3, forKey: "video")
        XCTAssertNil(oldData)
    }

    func testAvailableBytesRemainImmutableWithinOneGeneration() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)
        let generation = Data("v1".utf8)
        _ = try await cache.prepare(
            capacity: 8,
            generation: generation,
            forKey: "video"
        )
        _ = try await cache.insert(
            Data(repeating: 1, count: 8),
            at: 0,
            forKey: "video"
        )

        _ = try await cache.insert(
            Data(repeating: 2, count: 8),
            at: 0,
            forKey: "video"
        )

        let loaded = try await cache.data(in: 0..<8, forKey: "video")
        XCTAssertEqual(loaded, Data(repeating: 1, count: 8))
    }

    func testMetadataChangePreservesRangesWithinGeneration() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)
        let generation = Data("v1".utf8)

        _ = try await cache.prepare(
            capacity: 32,
            generation: generation,
            metadata: Data("old".utf8),
            forKey: "video"
        )
        _ = try await cache.insert(Data([1, 2, 3]), at: 4, forKey: "video")
        let updated = try await cache.prepare(
            capacity: 32,
            generation: generation,
            metadata: Data("new".utf8),
            forKey: "video"
        )

        XCTAssertEqual(updated.ranges, [4..<7])
        XCTAssertEqual(updated.metadata, Data("new".utf8))
    }

    func testOutOfOrderAndBridgingWritesKeepRangesNormalized() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)
        _ = try await cache.prepare(capacity: 16, forKey: "video")

        for offset in [8, 0, 4]
        {
            _ = try await cache.insert(
                Data(repeating: 1, count: 2),
                at: offset,
                forKey: "video"
            )
        }
        let bridged = try await cache.insert(
            Data(repeating: 1, count: 3),
            at: 2,
            forKey: "video"
        )
        XCTAssertEqual(bridged.ranges, [0..<6, 8..<10])

        let completeBridge = try await cache.insert(
            Data(repeating: 1, count: 2),
            at: 6,
            forKey: "video"
        )
        XCTAssertEqual(completeBridge.ranges, [0..<10])
    }

    func testDisjointConcurrentWritesProduceOneCoherentEntry() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)
        let chunkSize = 4096
        let chunkCount = 64
        _ = try await cache.prepare(
            capacity: chunkSize * chunkCount,
            generation: Data("v1".utf8),
            forKey: "video"
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<chunkCount
            {
                group.addTask {
                    let byte = UInt8(truncatingIfNeeded: index)
                    _ = try await cache.insert(
                        Data(repeating: byte, count: chunkSize),
                        at: index * chunkSize,
                        forKey: "video"
                    )
                }
            }
            try await group.waitForAll()
        }

        let loadedSnapshot = try await cache.snapshot(forKey: "video")
        let snapshot = try XCTUnwrap(loadedSnapshot)
        XCTAssertEqual(snapshot.ranges, [0..<(chunkSize * chunkCount)])
        XCTAssertTrue(snapshot.isComplete)
        for index in 0..<chunkCount
        {
            let range = (index * chunkSize)..<((index + 1) * chunkSize)
            let loadedData = try await cache.data(in: range, forKey: "video")
            let data = try XCTUnwrap(loadedData)
            XCTAssertEqual(data, Data(
                repeating: UInt8(truncatingIfNeeded: index),
                count: chunkSize
            ))
        }
    }

    func testOverlappingConcurrentWritesNeverProduceTornBytes() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)
        let byteCount = 256 * 1024
        _ = try await cache.prepare(capacity: byteCount, forKey: "video")

        try await withThrowingTaskGroup(of: Void.self) { group in
            for byte in UInt8(0)..<32
            {
                group.addTask {
                    _ = try await cache.insert(
                        Data(repeating: byte, count: byteCount),
                        at: 0,
                        forKey: "video"
                    )
                }
            }
            try await group.waitForAll()
        }

        let loaded = try await cache.data(in: 0..<byteCount, forKey: "video")
        let data = try XCTUnwrap(loaded)
        XCTAssertEqual(data.count, byteCount)
        XCTAssertEqual(Set(data).count, 1)
    }

    func testExpiredEntryRejectsAdditionalRangesUntilPreparedAgain() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)
        _ = try await cache.prepare(
            capacity: 32,
            expirationDate: .distantPast,
            forKey: "video"
        )

        do
        {
            _ = try await cache.insert(Data([1]), at: 0, forKey: "video")
            XCTFail("An expired entry must be prepared before accepting bytes")
        }
        catch SparseCacheError.entryExpired {}

        let snapshot = try await cache.snapshot(forKey: "video")
        XCTAssertNil(snapshot)
    }

    func testSparseEntryPersistsAcrossStorageInstances() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        do
        {
            let storage = try p_makeStorage(root: root)
            let cache = try SparseCache<String>(storage: storage)
            _ = try await cache.prepare(
                capacity: 32,
                generation: Data("v1".utf8),
                metadata: Data("meta".utf8),
                forKey: "video"
            )
            _ = try await cache.insert(Data([1, 2, 3]), at: 8, forKey: "video")
            try await cache.synchronize(forKey: "video")
        }

        let restoredStorage = try p_makeStorage(root: root)
        let restored = try SparseCache<String>(storage: restoredStorage)
        let loadedSnapshot = try await restored.snapshot(forKey: "video")
        let snapshot = try XCTUnwrap(loadedSnapshot)
        XCTAssertEqual(snapshot.ranges, [8..<11])
        XCTAssertEqual(snapshot.metadata, Data("meta".utf8))
        let restoredData = try await restored.data(in: 8..<11, forKey: "video")
        XCTAssertEqual(restoredData, Data([1, 2, 3]))
    }

    func testSynchronousSparseOperations() throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)

        _ = try cache.prepare(capacity: 16, forKey: "video")
        _ = try cache.insert(Data([1, 2, 3]), at: 2, forKey: "video")
        try cache.synchronize(forKey: "video")

        XCTAssertEqual(try cache.data(in: 2..<5, forKey: "video"), Data([1, 2, 3]))
        try cache.removeValue(forKey: "video")
        XCTAssertNil(try cache.snapshot(forKey: "video"))
    }

    func testPreparingLargeLogicalCapacityDoesNotAllocateWholeFile() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)
        let logicalCapacity = 64 * 1024 * 1024

        _ = try await cache.prepare(capacity: logicalCapacity, forKey: "video")
        try await cache.synchronize(forKey: "video")

        let report = try await storage.performMaintenance(.forced)
        XCTAssertNotNil(report.remainingCapacity)
        XCTAssertLessThan(report.remainingCapacity ?? .max, UInt64(logicalCapacity / 4))
    }

    func testStorageMaintenanceRemovesExpiredObjectAndSparseEntries() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let objectCache = try Cache(stores: [
            try CacheStore<String, Data>.disk(storage: storage),
        ])
        let sparseCache = try SparseCache<String>(storage: storage)

        try await objectCache.insert(
            Data([1]),
            forKey: "object",
            expirationDate: .distantPast
        )
        _ = try await sparseCache.prepare(
            capacity: 32,
            expirationDate: .distantPast,
            forKey: "video"
        )
        let report = try await storage.performMaintenance(.forced)

        XCTAssertEqual(report.scannedEntryCount, 2)
        XCTAssertEqual(report.removedEntryCount, 2)
        XCTAssertEqual(report.remainingEntryCount, 0)
        let object = try await objectCache.value(forKey: "object")
        let sparse = try await sparseCache.snapshot(forKey: "video")
        XCTAssertNil(object)
        XCTAssertNil(sparse)
    }

    func testDispatcherRemoveAllDoesNotMutateSpecializedNamespace() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let objectCache = try Cache(stores: [
            try CacheStore<String, Data>.disk(storage: storage),
        ])
        let sparseCache = try SparseCache<String>(storage: storage)

        try await objectCache.insert(Data([1]), forKey: "object")
        _ = try await sparseCache.prepare(capacity: 32, forKey: "video")
        _ = try await sparseCache.insert(Data([2]), at: 4, forKey: "video")

        try await objectCache.removeAll()

        let object = try await objectCache.value(forKey: "object")
        let sparse = try await sparseCache.data(in: 4..<5, forKey: "video")
        XCTAssertNil(object)
        XCTAssertEqual(sparse, Data([2]))

        try await storage.removeAll()
        let removedSparse = try await sparseCache.snapshot(forKey: "video")
        XCTAssertNil(removedSparse)
    }

    func testSnapshotZeroMaximumLengthReturnsNoRange() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)
        _ = try await cache.prepare(capacity: 16, forKey: "video")
        _ = try await cache.insert(
            Data(repeating: 1, count: 16),
            at: 0,
            forKey: "video"
        )
        let loadedSnapshot = try await cache.snapshot(forKey: "video")
        let snapshot = try XCTUnwrap(loadedSnapshot)

        XCTAssertNil(
            snapshot.contiguousRange(
                in: 0..<16,
                from: 4,
                maximumLength: 0
            )
        )
    }

    func testInvalidRangesAreRejectedWithoutChangingEntry() async throws
    {
        let (storage, root) = try p_makeStorage()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = try SparseCache<String>(storage: storage)
        _ = try await cache.prepare(capacity: 8, forKey: "video")

        for (offset, data) in [
            (-1, Data([1])),
            (8, Data([1])),
            (0, Data()),
        ]
        {
            do
            {
                _ = try await cache.insert(data, at: offset, forKey: "video")
                XCTFail("Invalid range should fail")
            }
            catch SparseCacheError.invalidRange {}
        }

        let loadedSnapshot = try await cache.snapshot(forKey: "video")
        XCTAssertTrue(try XCTUnwrap(loadedSnapshot).ranges.isEmpty)
    }

    internal func p_makeStorage() throws -> (DiskCacheStorage, URL)
    {
        let root = try p_makeCacheTemporaryDirectory()
        return (try p_makeStorage(root: root), root)
    }

    internal func p_makeStorage(root: URL) throws -> DiskCacheStorage
    {
        try DiskCacheStorage(
            name: "sparse-tests",
            location: .custom(root),
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
    }
}
