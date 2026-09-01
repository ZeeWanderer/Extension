//
//  CacheStressTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal actor P_CacheStressLedger
{
    internal var revisions: [Int: Int] = [:]

    internal func advance(_ key: Int) -> Int
    {
        let revision = (revisions[key] ?? 0) + 1
        revisions[key] = revision
        return revision
    }

    internal func snapshot() -> [Int: Int]
    {
        revisions
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheStressTests: XCTestCase
{
    func testHighContentionSingleKeyAsyncReadsAndWritesRemainAtomic() async throws
    {
        let cache = Cache<String, Int>()
        try await cache.insert(0, forKey: "shared")
        let writerCount = 64
        let writesPerWriter = 250
        let readerCount = 64
        let readsPerReader = 500

        try await withThrowingTaskGroup(of: Void.self) { group in
            for writer in 0..<writerCount
            {
                group.addTask {
                    for revision in 0..<writesPerWriter
                    {
                        try await cache.insert(
                            writer * writesPerWriter + revision,
                            forKey: "shared"
                        )
                    }
                }
            }
            for _ in 0..<readerCount
            {
                group.addTask {
                    for _ in 0..<readsPerReader
                    {
                        let value = try await cache.value(forKey: "shared")
                        XCTAssertNotNil(value)
                    }
                }
            }
            try await group.waitForAll()
        }

        let optionalFinalValue = try await cache.value(forKey: "shared")
        let finalValue = try XCTUnwrap(optionalFinalValue)
        XCTAssertTrue((0..<(writerCount * writesPerWriter)).contains(finalValue))
    }

    func testManyKeyAsyncStressProducesOnlyCompleteValuesForEachKey() async throws
    {
        let cache = Cache<Int, Int>()
        let ledger = P_CacheStressLedger()
        let keyCount = 512
        let workerCount = 128
        let operationsPerWorker = 1_000

        try await withThrowingTaskGroup(of: Void.self) { group in
            for worker in 0..<workerCount
            {
                group.addTask {
                    var generator = P_CacheSeededGenerator(
                        seed: UInt64(worker + 1) &* 0x9e3779b97f4a7c15
                    )
                    for operation in 0..<operationsPerWorker
                    {
                        let key = Int.random(in: 0..<keyCount, using: &generator)
                        if operation.isMultiple(of: 4)
                        {
                            _ = try await cache.value(forKey: key)
                        }
                        else
                        {
                            let revision = await ledger.advance(key)
                            try await cache.insert(revision, forKey: key)
                        }
                    }
                }
            }
            try await group.waitForAll()
        }

        let assignedRevisions = await ledger.snapshot()
        for (key, maximumAssignedRevision) in assignedRevisions
        {
            let value = try await cache.value(forKey: key)
            let revision = try XCTUnwrap(value)
            XCTAssertTrue((1...maximumAssignedRevision).contains(revision))
        }

        for key in 0..<keyCount
        {
            let canonical = Int.max - key
            try await cache.insert(canonical, forKey: key)
        }
        for key in 0..<keyCount
        {
            let value = try await cache.value(forKey: key)
            XCTAssertEqual(value, Int.max - key)
        }
    }

    func testKeyGateChurnBeyondRetentionLimitDoesNotLoseIsolation() async throws
    {
        let backend = P_CacheIntStoreBackend(id: "memory")
        let cache = try Cache(
            stores: [backend.makeStore()],
            retainedKeyGateLimit: 8
        )

        for round in 0..<20
        {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for key in 0..<2_000
                {
                    group.addTask {
                        let encoded = round * 10_000 + key
                        try await cache.insert(encoded, forKey: String(key))
                        let value = try await cache.value(forKey: String(key))
                        XCTAssertEqual(value, encoded)
                    }
                }
                try await group.waitForAll()
            }
        }

        for key in 0..<2_000
        {
            let value = try await cache.value(forKey: String(key))
            XCTAssertEqual(value, 19 * 10_000 + key)
        }
    }

    func testDynamicRoutingAcrossTwoMemoryTiersRemainsConsistent() async throws
    {
        let primary = P_CacheIntStoreBackend(id: "primary")
        let secondary = P_CacheIntStoreBackend(id: "secondary")
        let cache = try Cache(
            stores: [primary.makeStore(), secondary.makeStore()],
            routeProvider: { key in
                if Int(key)! % 2 == 0
                {
                    return CacheRoute(
                        readStages: [["primary"], ["secondary"]],
                        writeStores: ["primary"],
                        promotions: ["secondary": ["primary"]]
                    )
                }
                return CacheRoute(
                    readStages: [["secondary"], ["primary"]],
                    writeStores: ["secondary"],
                    promotions: ["primary": ["secondary"]]
                )
            }
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for key in 0..<2_000
            {
                group.addTask {
                    for revision in 0..<25
                    {
                        try await cache.insert(revision, forKey: String(key))
                        let value = try await cache.value(forKey: String(key))
                        XCTAssertEqual(value, revision)
                    }
                }
            }
            try await group.waitForAll()
        }

        for key in 0..<2_000
        {
            let encodedKey = String(key)
            if key.isMultiple(of: 2)
            {
                XCTAssertEqual(primary.entry(for: encodedKey)?.value, 24)
                XCTAssertNil(secondary.entry(for: encodedKey))
            }
            else
            {
                XCTAssertNil(primary.entry(for: encodedKey))
                XCTAssertEqual(secondary.entry(for: encodedKey)?.value, 24)
            }
        }
    }

    func testRepeatedRemoveAllRacesDoNotLeaveIncoherentCrossStoreValues() async throws
    {
        let first = P_CacheIntStoreBackend(id: "first")
        let second = P_CacheIntStoreBackend(id: "second")
        let cache = try Cache(stores: [first.makeStore(), second.makeStore()])

        try await withThrowingTaskGroup(of: Void.self) { group in
            for worker in 0..<32
            {
                group.addTask {
                    for revision in 0..<250
                    {
                        try await cache.insert(
                            worker * 1_000 + revision,
                            forKey: String(worker)
                        )
                    }
                }
            }
            group.addTask {
                for _ in 0..<100
                {
                    try await cache.removeAll()
                    await Task.yield()
                }
            }
            try await group.waitForAll()
        }

        for key in 0..<32
        {
            XCTAssertEqual(
                first.entry(for: String(key))?.value,
                second.entry(for: String(key))?.value
            )
            let value = try await cache.value(forKey: String(key))
            XCTAssertEqual(
                value,
                first.entry(for: String(key))?.value
            )
        }
    }

    func testReadOnlyCancellationStormDoesNotStrandKeyGates() async throws
    {
        let cache = Cache<Int, Int>()
        for key in 0..<512
        {
            try await cache.insert(key, forKey: key)
        }

        let tasks = (0..<5_000).map { operation in
            Task {
                try await cache.value(forKey: operation % 512)
            }
        }
        for (index, task) in tasks.enumerated() where index.isMultiple(of: 3)
        {
            task.cancel()
        }
        for task in tasks
        {
            _ = try? await task.value
        }

        for key in 0..<512
        {
            try await cache.insert(key + 1, forKey: key)
            let value = try await cache.value(forKey: key)
            XCTAssertEqual(value, key + 1)
        }
    }

    func testDiskCapacityMaintenanceRacingWritesLeavesOnlyCompleteEntries() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let trimCapacity: UInt64 = 128 * 1024
        let maximumCapacity: UInt64 = 256 * 1024
        let configuration = DiskCacheConfiguration(
            name: "capacity-stress",
            rootDirectory: root,
            capacityPolicy: .hard(
                maximumCapacity: maximumCapacity,
                trimToCapacity: trimCapacity
            ),
            minimumMaintenanceInterval: 0,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false,
            maximumConcurrentMaintenanceOperations: 8
        )
        let keyCount = 64
        let revisionCount = 40
        let payloadSize = 4 * 1024

        do
        {
            let cache = try Cache(stores: [
                CacheStore<String, Data>.disk(
                    configuration: configuration
                ),
            ])
            try await withThrowingTaskGroup(of: Void.self) { group in
                for key in 0..<keyCount
                {
                    group.addTask {
                        for revision in 0..<revisionCount
                        {
                            var value = Data([
                                UInt8(key),
                                UInt8(revision),
                            ])
                            value.append(
                                Data(
                                    repeating: UInt8(revision),
                                    count: payloadSize - value.count
                                )
                            )
                            try await cache.insert(
                                value,
                                forKey: String(key)
                            )
                        }
                    }
                }
                group.addTask {
                    for _ in 0..<revisionCount
                    {
                        _ = try await cache.performMaintenance(
                            mode: .aggressive
                        )
                        await Task.yield()
                    }
                }
                try await group.waitForAll()
            }

            let report = try await cache.performMaintenance(
                mode: .aggressive
            )
            XCTAssertLessThanOrEqual(
                report[storeID: .disk]?.remainingCapacity ?? .max,
                maximumCapacity
            )
            for key in 0..<keyCount
            {
                if let value = try await cache.value(forKey: String(key))
                {
                    p_assertCompleteStressPayload(
                        value,
                        key: key,
                        payloadSize: payloadSize
                    )
                }
            }
        }

        let reopened = try Cache(stores: [
            CacheStore<String, Data>.disk(
                configuration: configuration
            ),
        ])
        for key in 0..<keyCount
        {
            if let value = try await reopened.value(forKey: String(key))
            {
                p_assertCompleteStressPayload(
                    value,
                    key: key,
                    payloadSize: payloadSize
                )
            }
        }
    }
}

internal func p_assertCompleteStressPayload(
    _ value: Data,
    key: Int,
    payloadSize: Int,
    file: StaticString = #filePath,
    line: UInt = #line
)
{
    XCTAssertEqual(value.count, payloadSize, file: file, line: line)
    guard value.count == payloadSize else { return }
    XCTAssertEqual(value[0], UInt8(key), file: file, line: line)
    let revision = value[1]
    XCTAssertTrue(
        value.dropFirst(2).allSatisfy { $0 == revision },
        file: file,
        line: line
    )
}
