//
//  DiskCacheMaintenancePolicyTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
@testable import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class DiskCacheMaintenancePolicyTests: XCTestCase
{
    func testAdaptiveCapacityResolvesAStableBoundedPolicy()
    {
        let adaptive = DiskCacheAdaptiveCapacityPolicy(
            availableCapacityFraction: 0.1,
            maximumCapacity: 1_000,
            preferredCapacityFraction: 0.5,
            trimToCapacityFraction: 0.5,
            recentAccessProtectionInterval: 30
        )

        let policy = adaptive.capacityPolicy(
            availableCapacity: 9_000,
            existingCacheCapacity: 1_000
        )

        XCTAssertEqual(policy.maximumCapacity, 1_000)
        XCTAssertEqual(policy.preferredCapacity, 500)
        XCTAssertEqual(policy.trimToCapacity, 250)
        XCTAssertEqual(policy.recentAccessProtectionInterval, 30)
    }

    func testAdaptiveCapacityIncludesExistingAllocationWithoutExceedingItsCap()
    {
        let adaptive = DiskCacheAdaptiveCapacityPolicy(
            availableCapacityFraction: 0.5,
            maximumCapacity: 1_000,
            preferredCapacityFraction: 1,
            trimToCapacityFraction: 1
        )

        XCTAssertEqual(
            adaptive.capacityPolicy(
                availableCapacity: 500,
                existingCacheCapacity: 500
            ).maximumCapacity,
            500
        )
        XCTAssertEqual(
            adaptive.capacityPolicy(
                availableCapacity: 10_000,
                existingCacheCapacity: 500
            ).maximumCapacity,
            1_000
        )
    }

    func testAdaptiveCapacityNormalizesFractions()
    {
        let policy = DiskCacheAdaptiveCapacityPolicy(
            availableCapacityFraction: .nan,
            preferredCapacityFraction: 2,
            trimToCapacityFraction: -1,
            recentAccessProtectionInterval: .nan
        )

        XCTAssertEqual(policy.availableCapacityFraction, 0.1)
        XCTAssertEqual(policy.preferredCapacityFraction, 1)
        XCTAssertEqual(policy.trimToCapacityFraction, 0)
        XCTAssertEqual(policy.recentAccessProtectionInterval, 0)

        XCTAssertNoThrow(
            DiskCacheAdaptiveCapacityPolicy(
                availableCapacityFraction: 0.999_999_999_999_999_9,
                maximumCapacity: .max,
                preferredCapacityFraction: 1,
                trimToCapacityFraction: 1
            ).capacityPolicy(
                availableCapacity: .max,
                existingCacheCapacity: .max
            )
        )
    }

    func testAutomaticCapacityTriggersAreEdgeTriggeredAtBothWatermarks()
    {
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        let policy = CacheCapacityPolicy.soft(
            preferredCapacity: 100,
            trimToCapacity: 75,
            maximumCapacity: 150,
            recentAccessProtectionInterval: 60
        )
        let coordinator = P_CacheDiskDirectoryCoordinator(totalCapacity: 90)

        XCTAssertNil(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: policy,
            minimumInterval: .greatestFiniteMagnitude,
            now: now
        ))

        coordinator.updateTotalCapacity(from: 90, to: 101)
        XCTAssertEqual(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: policy,
            minimumInterval: .greatestFiniteMagnitude,
            now: now
        ), .capacity)
        coordinator.endAutomaticMaintenance()
        XCTAssertNil(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: policy,
            minimumInterval: .greatestFiniteMagnitude,
            now: now
        ))

        coordinator.updateTotalCapacity(from: 101, to: 151)
        XCTAssertEqual(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: policy,
            minimumInterval: .greatestFiniteMagnitude,
            now: now
        ), .capacity)
        coordinator.endAutomaticMaintenance()
        XCTAssertNil(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: policy,
            minimumInterval: .greatestFiniteMagnitude,
            now: now
        ))

        coordinator.updateTotalCapacity(from: 151, to: 75)
        XCTAssertNil(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: policy,
            minimumInterval: .greatestFiniteMagnitude,
            now: now
        ))
        coordinator.updateTotalCapacity(from: 75, to: 101)
        XCTAssertEqual(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: policy,
            minimumInterval: .greatestFiniteMagnitude,
            now: now
        ), .capacity)
    }

    func testReconciliationUsesItsOwnCadence()
    {
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        let coordinator = P_CacheDiskDirectoryCoordinator(totalCapacity: 0)
        coordinator.markMaintenanceCompleted(at: now)

        XCTAssertNil(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: .unlimited,
            minimumInterval: 3_600,
            now: now.addingTimeInterval(3_599)
        ))
        XCTAssertEqual(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: .unlimited,
            minimumInterval: 3_600,
            now: now.addingTimeInterval(3_600)
        ), .reconciliation)
        XCTAssertFalse(coordinator.endAutomaticMaintenance())

        coordinator.markMaintenanceCompleted(
            at: now.addingTimeInterval(3_600)
        )
        XCTAssertEqual(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: .unlimited,
            minimumInterval: 3_600,
            now: now.addingTimeInterval(7_200)
        ), .reconciliation)
        XCTAssertNil(coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: .unlimited,
            minimumInterval: 3_600,
            now: now.addingTimeInterval(7_200)
        ))
        XCTAssertTrue(coordinator.endAutomaticMaintenance())
    }

    func testCapacityMaintenanceReusesTheReconciledIndex() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let storage = try DiskCacheStorage(
            name: "indexed-capacity",
            location: .custom(root),
            capacityPolicy: .hard(
                maximumCapacity: 20_000,
                trimToCapacity: 8_000
            ),
            minimumMaintenanceInterval: .greatestFiniteMagnitude,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(storage: storage),
        ])

        try await cache.insert(Data(repeating: 0, count: 1_024), forKey: "0")
        _ = try await storage.performMaintenance(.forced)
        let reconciledState = storage.p_coordinator.diskEntryIndexState()
        let reconciliationDate = storage.p_coordinator.state()
            .lastMaintenanceDate
        XCTAssertTrue(reconciledState.isComplete)

        var key = 1
        while storage.p_coordinator.state().totalCapacity <= 20_000
        {
            try await cache.insert(
                Data(repeating: UInt8(truncatingIfNeeded: key), count: 1_024),
                forKey: String(key)
            )
            key += 1
        }

        let report = try await storage.performMaintenance(.ifNeeded)
        let finalState = storage.p_coordinator.diskEntryIndexState()

        XCTAssertEqual(report.status, .completed)
        XCTAssertLessThanOrEqual(
            try XCTUnwrap(report.remainingCapacity),
            UInt64(8_000)
        )
        XCTAssertEqual(finalState.generation, reconciledState.generation)
        XCTAssertEqual(
            storage.p_coordinator.state().lastMaintenanceDate,
            reconciliationDate
        )
    }

    func testRepeatedAutomaticPreferredCrossingsReuseTheIndex() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let preferredCapacity = UInt64(20_000)
        let trimToCapacity = UInt64(8_000)
        let storage = try DiskCacheStorage(
            name: "automatic-indexed-capacity",
            location: .custom(root),
            capacityPolicy: .soft(
                preferredCapacity: preferredCapacity,
                trimToCapacity: trimToCapacity,
                maximumCapacity: 100_000,
                recentAccessProtectionInterval: 0
            ),
            minimumMaintenanceInterval: .greatestFiniteMagnitude,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: true
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(storage: storage),
        ])

        var nextKey = 0
        await storage.p_coordinator.maintenanceGate.acquire(.write)
        while storage.p_coordinator.state().totalCapacity
            <= preferredCapacity
        {
            try await cache.insert(
                Data(
                    repeating: UInt8(truncatingIfNeeded: nextKey),
                    count: 1_024
                ),
                forKey: String(nextKey)
            )
            nextKey += 1
        }
        XCTAssertTrue(
            storage.p_coordinator.automaticMaintenanceState().isScheduled
        )
        storage.p_coordinator.maintenanceGate.release(.write)
        try await p_waitForAutomaticMaintenance(
            storage,
            capacityAtMost: trimToCapacity
        )

        let reconciledState = storage.p_coordinator.diskEntryIndexState()
        let reconciliationDate = storage.p_coordinator.state()
            .lastMaintenanceDate
        XCTAssertTrue(reconciledState.isComplete)
        XCTAssertGreaterThan(reconciledState.generation, 0)

        await storage.p_coordinator.maintenanceGate.acquire(.write)
        while storage.p_coordinator.state().totalCapacity
            <= preferredCapacity
        {
            try await cache.insert(
                Data(
                    repeating: UInt8(truncatingIfNeeded: nextKey),
                    count: 1_024
                ),
                forKey: String(nextKey)
            )
            nextKey += 1
        }
        XCTAssertTrue(
            storage.p_coordinator.automaticMaintenanceState().isScheduled
        )
        storage.p_coordinator.maintenanceGate.release(.write)
        try await p_waitForAutomaticMaintenance(
            storage,
            capacityAtMost: trimToCapacity
        )

        XCTAssertEqual(
            storage.p_coordinator.diskEntryIndexState().generation,
            reconciledState.generation
        )
        XCTAssertEqual(
            storage.p_coordinator.state().lastMaintenanceDate,
            reconciliationDate
        )
    }

    func testRemovingSparseNamespaceRemovesItsIndexedEntries() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let storage = try DiskCacheStorage(
            name: "sparse-index-removal",
            location: .custom(root),
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let sparseCache = try SparseCache<String>(storage: storage)

        _ = try await sparseCache.prepare(capacity: 32, forKey: "video")
        _ = try await sparseCache.insert(Data([1, 2, 3]), at: 4, forKey: "video")
        try await sparseCache.synchronize(forKey: "video")
        _ = try await storage.performMaintenance(.forced)
        XCTAssertEqual(storage.p_coordinator.indexedDiskEntries()?.count, 1)

        try await sparseCache.removeAll()

        let remainingRecords = storage.p_coordinator.indexedDiskEntries()
        let remainingPaths = remainingRecords?.map {
            "\($0.primaryURL.path) [\($0.primaryURL.standardizedFileURL.path)]"
        } ?? []
        XCTAssertEqual(
            remainingRecords?.count,
            0,
            "directory: \(sparseCache.p_directory.path), records: "
                + "\(remainingPaths)"
        )
        XCTAssertEqual(storage.p_coordinator.state().totalCapacity, 0)
    }

    func testReconciliationDoesNotTraverseSparseNamespaceSymlink() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let storage = try DiskCacheStorage(
            name: "symlink-boundary",
            location: .custom(root),
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let outsideDirectory = root.appendingPathComponent(
            "outside",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: outsideDirectory,
            withIntermediateDirectories: true
        )
        let outsideFile = outsideDirectory.appendingPathComponent(
            "must-survive.cache",
            isDirectory: false
        )
        let expected = Data([0xde, 0xad, 0xbe, 0xef])
        try expected.write(to: outsideFile)
        let namespaceLink = storage.directoryURL.appendingPathComponent(
            "escape.sparse",
            isDirectory: true
        )
        try FileManager.default.createSymbolicLink(
            at: namespaceLink,
            withDestinationURL: outsideDirectory
        )

        _ = try await storage.performMaintenance(.forced)

        XCTAssertEqual(try Data(contentsOf: outsideFile), expected)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: namespaceLink.path)
        )
    }

    internal func p_waitForAutomaticMaintenance(
        _ storage: DiskCacheStorage,
        capacityAtMost capacity: UInt64,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws
    {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(10))
        while clock.now < deadline
        {
            let state = storage.p_coordinator.state()
            let automaticState = storage.p_coordinator
                .automaticMaintenanceState()
            if state.totalCapacity <= capacity,
               !automaticState.isScheduled
            {
                return
            }
            try await Task.sleep(for: .milliseconds(1))
        }
        XCTFail(
            "Automatic maintenance did not reach its trim target",
            file: file,
            line: line
        )
    }
}
