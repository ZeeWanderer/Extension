//
//  CacheConfigurationTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

internal struct P_CacheCompositeKey: Codable, Equatable, Sendable
{
    internal let name: String
    internal let revision: Int
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheConfigurationTests: XCTestCase
{
    func testKeyEncodersExposeStableClientFacingRepresentations() throws
    {
        let custom = CacheKeyEncoder<Int> { value in
            Data(String(value, radix: 16).utf8)
        }
        XCTAssertEqual(
            try custom.encode(255),
            Data("ff".utf8)
        )
        XCTAssertEqual(
            try CacheKeyEncoder<String>.utf8.encode("cache-🗄️"),
            Data("cache-🗄️".utf8)
        )

        let key = P_CacheCompositeKey(name: "athlete", revision: 7)
        let firstEncoding = try CacheKeyEncoder<P_CacheCompositeKey>.json
            .encode(key)
        let secondEncoding = try CacheKeyEncoder<P_CacheCompositeKey>.json
            .encode(key)
        XCTAssertEqual(firstEncoding, secondEncoding)
        XCTAssertEqual(
            try JSONDecoder().decode(
                P_CacheCompositeKey.self,
                from: firstEncoding
            ),
            key
        )
    }

    func testValueTypesPreserveAndNormalizeTheirPublicConfiguration()
    {
        let now = Date.now
        let entry = CacheEntry(
            42,
            storedAt: now,
            expirationDate: now,
            cost: -10
        )
        XCTAssertEqual(entry.value, 42)
        XCTAssertEqual(entry.storedAt, now)
        XCTAssertEqual(entry.expirationDate, now)
        XCTAssertEqual(entry.cost, 0)
        XCTAssertTrue(entry.isExpired(at: now))
        XCTAssertFalse(entry.isExpired(at: now.addingTimeInterval(-0.001)))

        let memory = MemoryCacheConfiguration(
            name: "configured",
            countLimit: -1,
            totalCostLimit: -2,
            evictsObjectsWithDiscardedContent: true
        )
        XCTAssertEqual(memory.name, "configured")
        XCTAssertEqual(memory.countLimit, 0)
        XCTAssertEqual(memory.totalCostLimit, 0)
        XCTAssertTrue(memory.evictsObjectsWithDiscardedContent)

        let adaptiveCapacity = DiskCacheAdaptiveCapacityPolicy(
            maximumCapacity: 512 * 1024 * 1024
        )
        let disk = DiskCacheConfiguration(
            adaptiveCapacityPolicy: adaptiveCapacity,
            minimumMaintenanceInterval: .nan,
            minimumAccessDateUpdateInterval: .nan,
            maximumUnusedInterval: .nan,
            removesExpiredEntries: false,
            performsAutomaticMaintenance: false,
            maximumConcurrentMaintenanceOperations: 0
        )
        XCTAssertEqual(disk.minimumMaintenanceInterval, 0)
        XCTAssertEqual(disk.adaptiveCapacityPolicy, adaptiveCapacity)
        XCTAssertEqual(disk.minimumAccessDateUpdateInterval, 0)
        XCTAssertEqual(disk.maximumUnusedInterval, 0)
        XCTAssertFalse(disk.removesExpiredEntries)
        XCTAssertFalse(disk.performsAutomaticMaintenance)
        XCTAssertEqual(disk.maximumConcurrentMaintenanceOperations, 1)

        let maintenance = CacheStoreMaintenanceResult(
            status: .completed,
            scannedEntryCount: -1,
            removedEntryCount: -2,
            capacityUnit: "database-pages",
            removedCapacity: 4,
            remainingEntryCount: -3,
            remainingCapacity: 5,
            protectedEntryCount: -6,
            protectedCapacity: 7,
            didExceedMaximumCapacity: true
        )
        XCTAssertEqual(maintenance.scannedEntryCount, 0)
        XCTAssertEqual(maintenance.removedEntryCount, 0)
        XCTAssertEqual(maintenance.capacityUnit, "database-pages")
        XCTAssertEqual(maintenance.removedCapacity, 4)
        XCTAssertEqual(maintenance.remainingEntryCount, 0)
        XCTAssertEqual(maintenance.remainingCapacity, 5)
        XCTAssertEqual(maintenance.protectedEntryCount, 0)
        XCTAssertEqual(maintenance.protectedCapacity, 7)
        XCTAssertTrue(maintenance.didExceedMaximumCapacity)
        XCTAssertEqual(CacheStoreMaintenanceResult.unsupported.status, .unsupported)
    }

    func testStoreIdentifiersAndHierarchyPreserveStableOrdering()
    {
        let ids: [CacheStoreID] = ["memory-0", "memory-1", "disk"]
        XCTAssertEqual(ids[0].rawValue, "memory-0")
        XCTAssertEqual(ids[1].description, "memory-1")
        XCTAssertEqual(CacheStoreID.memory, "memory")
        XCTAssertEqual(CacheStoreID.disk, "disk")

        let route = CacheRoute.hierarchy(ids)
        XCTAssertEqual(route.readStages, ids.map { [$0] })
        XCTAssertEqual(route.writeStores, ids)
        XCTAssertEqual(route.promotions["memory-0"], nil)
        XCTAssertEqual(route.promotions["memory-1"], ["memory-0"])
        XCTAssertEqual(route.promotions["disk"], ["memory-0", "memory-1"])
    }

    func testEmptyAndDuplicateStoreConfigurationsAreRejected() throws
    {
        XCTAssertThrowsError(
            try Cache<String, Int>(stores: [])
        ) { error in
            guard case CacheError.emptyStoreList = error else
            {
                return XCTFail("Unexpected error: \(error)")
            }
        }

        let first = P_CacheIntStoreBackend(id: "duplicate").makeStore()
        let second = P_CacheIntStoreBackend(id: "duplicate").makeStore()
        XCTAssertThrowsError(
            try Cache(stores: [first, second])
        ) { error in
            guard case CacheError.duplicateStoreID("duplicate") = error else
            {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testFailedInitializationReleasesStoresClaimedEarlier() throws
    {
        let available = P_CacheIntStoreBackend(id: "available").makeStore()
        let occupied = P_CacheIntStoreBackend(id: "occupied").makeStore()
        let owner = try Cache(stores: [occupied])
        try withExtendedLifetime(owner)
        {
            XCTAssertThrowsError(
                try Cache(stores: [available, occupied])
            ) { error in
                guard case CacheError.storeAlreadyAttached("occupied") = error else { return XCTFail("Unexpected error: \(error)") }
            }

            XCTAssertNoThrow(try Cache(stores: [available]))
        }
    }

    func testStoreCanBeAttachedAgainAfterDispatcherDeinitialization() throws
    {
        let store = P_CacheIntStoreBackend(id: "reusable").makeStore()
        var cache: Cache<String, Int>? = try Cache(stores: [store])
        XCTAssertThrowsError(try Cache(stores: [store]))
        cache = nil
        XCTAssertNil(cache)
        XCTAssertNoThrow(try Cache(stores: [store]))
    }

    func testStoreIDsRemainInInitializerOrderAndRouteDuplicatesAreCollapsed() async throws
    {
        let firstBackend = P_CacheIntStoreBackend(id: "first")
        let secondBackend = P_CacheIntStoreBackend(id: "second")
        let cache = try Cache(stores: [
            firstBackend.makeStore(),
            secondBackend.makeStore(),
        ])
        XCTAssertEqual(cache.storeIDs, ["first", "second"])

        let route = CacheRoute(
            readStages: [["first", "first", "second", "second"]],
            writeStores: ["first", "first", "second", "second"]
        )
        try await cache.insert(7, forKey: "value", route: route)
        let value = try await cache.value(forKey: "value", route: route)
        XCTAssertEqual(value, 7)

        XCTAssertEqual(
            firstBackend.eventSnapshot().filter { $0.operation == .store }.count,
            1
        )
        XCTAssertEqual(
            secondBackend.eventSnapshot().filter { $0.operation == .store }.count,
            1
        )
        XCTAssertEqual(
            firstBackend.eventSnapshot().filter { $0.operation == .retrieve }.count,
            1
        )
        XCTAssertEqual(
            secondBackend.eventSnapshot().filter { $0.operation == .retrieve }.count,
            1
        )
    }

    func testSelfPromotionIsIgnored() async throws
    {
        let backend = P_CacheIntStoreBackend(id: "store")
        let cache = try Cache(stores: [backend.makeStore()])
        let route = CacheRoute(
            readStages: [["store"]],
            writeStores: ["store"],
            promotions: ["store": ["store", "store"]]
        )

        try await cache.insert(3, forKey: "key", route: route)
        backend.resetEvents()
        let value = try await cache.value(forKey: "key", route: route)
        XCTAssertEqual(value, 3)
        XCTAssertEqual(backend.eventSnapshot(), [
            .init(operation: .retrieve, key: "key"),
        ])
    }

    func testEveryRouteReferenceIsValidatedBeforeStoreAccess() async throws
    {
        let backend = P_CacheIntStoreBackend(id: "known")
        let cache = try Cache(stores: [backend.makeStore()])
        let routes = [
            CacheRoute(readStages: [["missing"]]),
            CacheRoute(writeStores: ["missing"]),
            CacheRoute(promotions: ["missing": ["known"]]),
            CacheRoute(promotions: ["known": ["missing"]]),
        ]

        for route in routes
        {
            do
            {
                _ = try await cache.value(forKey: "key", route: route)
                XCTFail("Expected route validation to fail")
            }
            catch CacheError.unknownStoreID("missing") {}
            catch { XCTFail("Unexpected error: \(error)") }
        }
        XCTAssertTrue(backend.eventSnapshot().isEmpty)
    }

    func testWriteRequiresAtLeastOneDestination() async throws
    {
        let cache = Cache<String, Int>()
        let readOnly = CacheRoute(readStages: [[.memory]])

        do
        {
            try await cache.insert(1, forKey: "key", route: readOnly)
            XCTFail("Expected an async no-write-store error")
        }
        catch CacheError.noWriteStores {}
        catch { XCTFail("Unexpected error: \(error)") }

        XCTAssertThrowsError(
            try p_insertSynchronously(
                1,
                into: cache,
                forKey: "key",
                route: readOnly
            )
        ) { error in
            guard case CacheError.noWriteStores = error else
            {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testDiskStoreRejectsUnsafeDirectoryNames() throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }

        for name in ["", ".", "..", "nested/cache"]
        {
            XCTAssertThrowsError(
                try CacheStore<String, Data>.disk(
                    configuration: .init(name: name, rootDirectory: root)
                )
            ) { error in
                guard case CacheError.invalidDiskConfiguration = error else
                {
                    return XCTFail("Unexpected error for \(name): \(error)")
                }
            }
        }
    }
}
