//
//  CacheDiskStoreTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheDiskStoreTests: XCTestCase
{
    func testDataPayloadsAcrossBoundarySizesRoundTripAfterReopening() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let sizes = [0, 1, 3, 4, 255, 256, 4_095, 4_096, 65_537, 1_048_577]
        let configuration = DiskCacheConfiguration(
            name: "boundaries",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: .greatestFiniteMagnitude,
            maximumUnusedInterval: nil
        )

        do
        {
            let cache = try Cache(stores: [
                CacheStore<String, Data>.disk(configuration: configuration),
            ])
            for size in sizes
            {
                let payload = Data((0..<size).map { UInt8(truncatingIfNeeded: $0) })
                try await cache.insert(payload, forKey: "size-\(size)")
            }
        }

        let reopened = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        for size in sizes
        {
            let expected = Data((0..<size).map { UInt8(truncatingIfNeeded: $0) })
            let value = try await reopened.value(forKey: "size-\(size)")
            XCTAssertEqual(value, expected)
        }
    }

    func testCodableValuesAndUnicodeKeysPersist() async throws
    {
        struct Payload: Codable, Equatable, Sendable
        {
            let identifier: UUID
            let values: [Int]
            let text: String
        }

        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "codable",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: .greatestFiniteMagnitude,
            maximumUnusedInterval: nil
        )
        let payload = Payload(
            identifier: UUID(),
            values: Array(-128...128),
            text: "Київ 🏋🏽‍♂️ é / ../ null\0"
        )

        do
        {
            let store = try CacheStore<String, Payload>.disk(
                configuration: configuration,
                keyEncoder: .utf8,
                valueCoder: .json
            )
            let cache = try Cache(stores: [store])
            try await cache.insert(payload, forKey: payload.text)
        }

        let reopenedStore = try CacheStore<String, Payload>.disk(
            configuration: configuration,
            keyEncoder: .utf8,
            valueCoder: .json
        )
        let reopened = try Cache(stores: [reopenedStore])
        let value = try await reopened.value(forKey: payload.text)
        XCTAssertEqual(value, payload)
    }

    func testCorruptEntriesThrowOnceAndAreRemoved() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "corruption",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: .greatestFiniteMagnitude,
            maximumUnusedInterval: nil
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        try await cache.insert(Data("valid".utf8), forKey: "key")
        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )
        let file = try XCTUnwrap(try p_cacheFiles(in: directory).first)
        let failingReadRoute = CacheRoute(
            readStages: [[.disk]],
            readFailurePolicy: .fail
        )

        for corruption in [
            Data(),
            Data([0, 0, 0, 200, 1, 2, 3]),
            Data(repeating: 0xff, count: 32),
        ]
        {
            try corruption.write(to: file, options: .atomic)
            do
            {
                _ = try await cache.value(
                    forKey: "key",
                    route: failingReadRoute
                )
                XCTFail("Expected corrupt data to fail")
            }
            catch
            {
                let failures = try p_cacheStoreFailures(from: error)
                XCTAssertEqual(failures.map(\.storeID), [.disk])
                XCTAssertEqual(failures.map(\.operation), [.retrieve])
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
            let value = try await cache.value(
                forKey: "key",
                route: failingReadRoute
            )
            XCTAssertNil(value)
            try corruption.write(to: file, options: .atomic)
        }
    }

    func testExpiredDiskEntryIsRemovedOnRead() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "expiration",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: .greatestFiniteMagnitude,
            maximumUnusedInterval: nil
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        try await cache.insert(
            Data([1]),
            forKey: "expired",
            expirationDate: .distantPast
        )
        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )
        XCTAssertEqual(try p_cacheFiles(in: directory).count, 1)
        let value = try await cache.value(forKey: "expired")
        XCTAssertNil(value)
        XCTAssertTrue(try p_cacheFiles(in: directory).isEmpty)
    }

    func testAllocatedCapacityEvictsOldestFilesUntilUnderTheLimit() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let capacityLimit: UInt64 = 6_000
        let configuration = DiskCacheConfiguration(
            name: "capacity-limit",
            rootDirectory: root,
            capacityPolicy: .hard(
                maximumCapacity: capacityLimit,
                trimToCapacity: capacityLimit
            ),
            minimumMaintenanceInterval: 0,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])

        for key in 0..<20
        {
            try await cache.insert(
                Data(repeating: UInt8(key), count: 1_024),
                forKey: String(key)
            )
            try await Task.sleep(for: .milliseconds(2))
        }

        let maintenance = try await cache.performMaintenance()
        XCTAssertEqual(maintenance[storeID: .disk]?.status, .completed)
        XCTAssertGreaterThan(
            maintenance[storeID: .disk]?.removedEntryCount ?? 0,
            0
        )

        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )
        let files = try p_cacheFiles(in: directory)
        let totalCapacity = try p_cacheAllocatedCapacity(in: directory)
        XCTAssertLessThanOrEqual(totalCapacity, capacityLimit)
        XCTAssertLessThan(files.count, 20)
        let oldest = try await cache.value(forKey: "0")
        let newest = try await cache.value(forKey: "19")
        XCTAssertNil(oldest)
        XCTAssertEqual(newest, Data(repeating: 19, count: 1_024))
    }

    func testMaximumUnusedIntervalEvictsStaleEntries() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "unused",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: 0,
            maximumUnusedInterval: 0,
            performsAutomaticMaintenance: false
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])

        try await cache.insert(Data([1]), forKey: "key")
        let maintenance = try await cache.performMaintenance()
        XCTAssertEqual(
            maintenance[storeID: .disk]?.removedEntryCount,
            1
        )
        let value = try await cache.value(forKey: "key")
        XCTAssertNil(value)
        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )
        XCTAssertTrue(try p_cacheFiles(in: directory).isEmpty)
    }

    func testRemoveAllRecreatesTheDirectoryAndAcceptsNewWrites() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "remove-all",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: .greatestFiniteMagnitude,
            maximumUnusedInterval: nil
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        for key in 0..<50
        {
            try await cache.insert(Data([UInt8(key)]), forKey: String(key))
        }

        try await cache.removeAll()
        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
        XCTAssertTrue(try p_cacheFiles(in: directory).isEmpty)

        try await cache.insert(Data([99]), forKey: "new")
        let value = try await cache.value(forKey: "new")
        XCTAssertEqual(value, Data([99]))
    }

    func testConcurrentDiskOperationsRemainReadableAfterReopening() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "concurrent",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: .greatestFiniteMagnitude,
            maximumUnusedInterval: nil
        )

        do
        {
            let cache = try Cache(stores: [
                CacheStore<String, Data>.disk(configuration: configuration),
            ])
            try await withThrowingTaskGroup(of: Void.self) { group in
                for key in 0..<200
                {
                    group.addTask {
                        let payload = Data(repeating: UInt8(truncatingIfNeeded: key), count: 4_096)
                        for revision in 0..<10
                        {
                            try await cache.insert(
                                payload + Data([UInt8(revision)]),
                                forKey: String(key)
                            )
                            let loaded = try await cache.value(forKey: String(key))
                            XCTAssertEqual(loaded, payload + Data([UInt8(revision)]))
                        }
                    }
                }
                try await group.waitForAll()
            }
        }

        let reopened = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        for key in 0..<200
        {
            let payload = Data(repeating: UInt8(truncatingIfNeeded: key), count: 4_096)
            let value = try await reopened.value(forKey: String(key))
            XCTAssertEqual(value, payload + Data([9]))
        }
    }
}
