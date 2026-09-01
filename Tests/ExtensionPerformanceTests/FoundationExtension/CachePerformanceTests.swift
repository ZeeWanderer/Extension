//
//  CachePerformanceTests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal final class P_CacheAsyncResult<Value: Sendable>: @unchecked Sendable
{
    internal let condition = NSCondition()
    internal var value: Value?

    internal func store(_ value: Value)
    {
        condition.lock()
        self.value = value
        condition.signal()
        condition.unlock()
    }

    internal func take() -> Value
    {
        condition.lock()
        while value == nil
        {
            condition.wait()
        }
        defer { condition.unlock() }
        return value!
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal func p_waitForCacheResult<Value: Sendable>(
    _ operation: @escaping @Sendable () async -> Value
) -> Value
{
    let result = P_CacheAsyncResult<Value>()
    Task.detached {
        let value = await operation()
        result.store(value)
    }
    return result.take()
}

internal func p_makeCachePerformanceDirectory() throws -> URL
{
    let directory = FileManager.default.temporaryDirectory
        .appending(
            component: "ExtensionCachePerformanceTests",
            directoryHint: .isDirectory
        )
        .appending(component: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    return directory
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CachePerformanceTests: ReleasePerformanceTestCase
{
    func testCapacityPlanningPerformance()
    {
        let candidateCount = 10_000
        let referenceDate = Date(timeIntervalSinceReferenceDate: 20_000)
        let candidates = (0..<candidateCount).map { index in
            let id = index * 7_919 % candidateCount
            return CacheCapacityPolicy.Candidate(
                id: id,
                capacity: 1,
                lastAccessDate: referenceDate.addingTimeInterval(Double(id))
            )
        }
        let policy = CacheCapacityPolicy.soft(
            preferredCapacity: 8_000,
            trimToCapacity: 6_000,
            maximumCapacity: 12_000,
            recentAccessProtectionInterval: 0
        )
        var evictionCount = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            let plan = policy.evictionPlan(
                currentCapacity: UInt64(candidateCount),
                candidates: candidates,
                at: referenceDate
            )
            evictionCount = plan.evictions.count
        }

        XCTAssertEqual(evictionCount, 4_000)
    }

    func testSynchronousMemoryCacheLookupPerformance() throws
    {
        let cache = Cache<Int, Int>()
        let operationCount = 100_000
        let keyCount = 4_096
        for key in 0..<keyCount
        {
            try cache.insert(key, forKey: key)
        }

        var checksum = 0
        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            for operation in 0..<operationCount
            {
                checksum &+= try! cache.value(forKey: operation % keyCount) ?? 0
            }
        }

        XCTAssertNotEqual(checksum, 0)
    }

    func testConcurrentAsyncMemoryCacheLookupPerformance() async throws
    {
        let cache = Cache<Int, Int>()
        let keyCount = 4_096
        for key in 0..<keyCount
        {
            try await cache.insert(key, forKey: key)
        }

        let operationCount = 100_000
        let workerCount = 100
        var checksum = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            checksum = p_waitForCacheResult {
                await withTaskGroup(of: Int.self) { group in
                    for worker in 0..<workerCount
                    {
                        group.addTask {
                            var result = 0
                            for operation in stride(
                                from: worker,
                                to: operationCount,
                                by: workerCount
                            )
                            {
                                result &+= try! await cache.value(
                                    forKey: operation % keyCount
                                ) ?? 0
                            }
                            return result
                        }
                    }

                    var result = 0
                    for await partialResult in group
                    {
                        result &+= partialResult
                    }
                    return result
                }
            }
        }

        XCTAssertNotEqual(checksum, 0)
    }

    func testSynchronousMemoryCacheMutationPerformance() throws
    {
        let cache = Cache<Int, Int>()
        let operationCount = 100_000
        let keyCount = 4_096

        measure(
            metrics: [XCTClockMetric(), XCTCPUMetric()],
            options: measurementOptions
        ) {
            for operation in 0..<operationCount
            {
                try! cache.insert(
                    operation,
                    forKey: operation % keyCount
                )
            }
        }

        XCTAssertNotNil(try cache.value(forKey: keyCount - 1))
    }

    func testConcurrentAsyncMixedMemoryCachePerformance() async throws
    {
        let cache = Cache<Int, Int>()
        let keyCount = 4_096
        for key in 0..<keyCount
        {
            try await cache.insert(key, forKey: key)
        }

        let operationCount = 100_000
        let workerCount = 100
        var checksum = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            checksum = p_waitForCacheResult {
                await withTaskGroup(of: Int.self) { group in
                    for worker in 0..<workerCount
                    {
                        group.addTask {
                            var result = 0
                            for operation in stride(
                                from: worker,
                                to: operationCount,
                                by: workerCount
                            )
                            {
                                let key = operation % keyCount
                                if operation.isMultiple(of: 8)
                                {
                                    try! await cache.insert(
                                        operation,
                                        forKey: key
                                    )
                                }
                                else
                                {
                                    result &+= try! await cache.value(
                                        forKey: key
                                    ) ?? 0
                                }
                            }
                            return result
                        }
                    }

                    var result = 0
                    for await partialResult in group
                    {
                        result &+= partialResult
                    }
                    return result
                }
            }
        }

        XCTAssertNotEqual(checksum, 0)
    }

    func testConcurrentAsyncDiskRoundTripPerformance() throws
    {
        let root = try p_makeCachePerformanceDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let store = try CacheStore<String, Data>.disk(
            configuration: DiskCacheConfiguration(
                name: "round-trip",
                rootDirectory: root,
                capacityPolicy: .unlimited,
                minimumMaintenanceInterval: 60 * 60,
                maximumUnusedInterval: nil
            )
        )
        let cache = try Cache(stores: [store])
        let payload = Data(repeating: 0xa5, count: 16 * 1_024)
        let operationCount = 256
        let workerCount = 32
        try cache.insert(payload, forKey: "warm-up")
        var checksum = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            checksum = p_waitForCacheResult {
                await withTaskGroup(of: Int.self) { group in
                    for worker in 0..<workerCount
                    {
                        group.addTask {
                            var result = 0
                            for operation in stride(
                                from: worker,
                                to: operationCount,
                                by: workerCount
                            )
                            {
                                let key = "entry-\(operation)"
                                try! await cache.insert(payload, forKey: key)
                                let value = try! await cache.value(forKey: key)
                                result &+= value?.count ?? 0
                            }
                            return result
                        }
                    }

                    var result = 0
                    for await partialResult in group
                    {
                        result &+= partialResult
                    }
                    return result
                }
            }
        }

        XCTAssertEqual(checksum, payload.count * operationCount)
    }

    func testAsyncTwoTierPromotionPerformance() throws
    {
        let root = try p_makeCachePerformanceDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let memory = CacheStore<String, Data>.memory(id: .memory)
        let disk = try CacheStore<String, Data>.disk(
            id: .disk,
            configuration: DiskCacheConfiguration(
                name: "promotion",
                rootDirectory: root,
                capacityPolicy: .unlimited,
                minimumMaintenanceInterval: 60 * 60,
                maximumUnusedInterval: nil
            )
        )
        let cache = try Cache(stores: [memory, disk])
        let diskOnly = CacheRoute(
            readStages: [[.disk]],
            writeStores: [.disk]
        )
        let promoteToMemory = CacheRoute(
            readStages: [[.memory], [.disk]],
            writeStores: [.memory, .disk],
            promotions: [.disk: [.memory]]
        )
        // XCTest performs one or more unmeasured warm-up invocations in
        // addition to the requested measured iterations.
        let preparedBatchCount = measurementOptions.iterationCount + 8
        let entryCount = 512
        let payload = Data(repeating: 0x5a, count: 4 * 1_024)
        for batch in 0..<preparedBatchCount
        {
            for entry in 0..<entryCount
            {
                try cache.insert(
                    payload,
                    forKey: "\(batch)-\(entry)",
                    route: diskOnly
                )
            }
        }

        var batch = 0
        var checksum = 0
        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            let measuredBatch = batch
            batch += 1
            checksum = p_waitForCacheResult {
                await withTaskGroup(of: Int.self) { group in
                    for entry in 0..<entryCount
                    {
                        group.addTask {
                            let value = try! await cache.value(
                                forKey: "\(measuredBatch)-\(entry)",
                                route: promoteToMemory
                            )
                            return value?.count ?? 0
                        }
                    }

                    var result = 0
                    for await count in group
                    {
                        result &+= count
                    }
                    return result
                }
            }
        }

        XCTAssertEqual(checksum, payload.count * entryCount)
        XCTAssertGreaterThan(batch, 0)
        XCTAssertLessThanOrEqual(batch, preparedBatchCount)
        let lastPromotedBatch = batch - 1
        for entry in 0..<entryCount
        {
            let value = try cache.value(
                forKey: "\(lastPromotedBatch)-\(entry)",
                route: CacheRoute(readStages: [[.memory]])
            )
            XCTAssertEqual(value?.count, payload.count)
        }
    }

    func testAsyncDiskMaintenanceScanPerformance() throws
    {
        let root = try p_makeCachePerformanceDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let store = try CacheStore<String, Data>.disk(
            configuration: DiskCacheConfiguration(
                name: "maintenance",
                rootDirectory: root,
                capacityPolicy: .unlimited,
                minimumMaintenanceInterval: 60 * 60,
                maximumUnusedInterval: nil,
                performsAutomaticMaintenance: false,
                maximumConcurrentMaintenanceOperations: 8
            )
        )
        let cache = try Cache(stores: [store])
        let entryCount = 1_000
        let payload = Data(repeating: 0xc3, count: 512)
        for entry in 0..<entryCount
        {
            try cache.insert(payload, forKey: String(entry))
        }

        var scannedEntryCount = 0
        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            scannedEntryCount = p_waitForCacheResult {
                let report = try! await cache.performMaintenance()
                return report[storeID: .disk]?.scannedEntryCount ?? 0
            }
        }

        XCTAssertEqual(scannedEntryCount, entryCount)
    }
}
