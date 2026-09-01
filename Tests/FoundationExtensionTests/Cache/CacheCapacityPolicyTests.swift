//
//  CacheCapacityPolicyTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheCapacityPolicyTests: XCTestCase
{
    func testCapacityPoliciesNormalizeInvalidBounds()
    {
        let policy = CacheCapacityPolicy(
            preferredCapacity: 100,
            trimToCapacity: 150,
            maximumCapacity: 80,
            recentAccessProtectionInterval: .nan
        )

        XCTAssertEqual(policy.preferredCapacity, 100)
        XCTAssertEqual(policy.trimToCapacity, 100)
        XCTAssertEqual(policy.maximumCapacity, 100)
        XCTAssertEqual(policy.recentAccessProtectionInterval, 0)
        XCTAssertFalse(policy.isUnlimited)

        XCTAssertTrue(CacheCapacityPolicy.unlimited.isUnlimited)
        XCTAssertNil(CacheCapacityPolicy.unlimited.preferredCapacity)
        XCTAssertNil(CacheCapacityPolicy.unlimited.trimToCapacity)
        XCTAssertNil(CacheCapacityPolicy.unlimited.maximumCapacity)
    }

    func testDefaultDiskPolicyUsesHysteresisAndAHardCeiling()
    {
        let configuration = DiskCacheConfiguration()

        XCTAssertEqual(
            configuration.capacityPolicy.preferredCapacity,
            400 * 1024 * 1024
        )
        XCTAssertEqual(
            configuration.capacityPolicy.trimToCapacity,
            300 * 1024 * 1024
        )
        XCTAssertEqual(
            configuration.capacityPolicy.maximumCapacity,
            600 * 1024 * 1024
        )
        XCTAssertEqual(
            configuration.capacityPolicy.recentAccessProtectionInterval,
            10 * 60
        )
        XCTAssertNil(configuration.adaptiveCapacityPolicy)
        XCTAssertEqual(configuration.minimumAccessDateUpdateInterval, 60)
    }

    func testSoftCapacityEvictsOldEntriesAndDefersRecentEntries()
    {
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        let policy = CacheCapacityPolicy.soft(
            preferredCapacity: 100,
            trimToCapacity: 75,
            maximumCapacity: 200,
            recentAccessProtectionInterval: 60
        )
        let plan = policy.evictionPlan(
            currentCapacity: 150,
            candidates: [
                .init(
                    id: "recent",
                    capacity: 80,
                    lastAccessDate: now.addingTimeInterval(-5)
                ),
                .init(
                    id: "old",
                    capacity: 70,
                    lastAccessDate: now.addingTimeInterval(-120)
                ),
            ],
            at: now
        )

        XCTAssertEqual(plan.evictions.map(\.id), ["old"])
        XCTAssertEqual(plan.projectedCapacity, 80)
        XCTAssertEqual(plan.protectedEntryCount, 1)
        XCTAssertEqual(plan.protectedCapacity, 80)
        XCTAssertFalse(plan.didExceedMaximumCapacity)
    }

    func testHardCeilingOverridesRecentAccessProtection()
    {
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        let policy = CacheCapacityPolicy.soft(
            preferredCapacity: 100,
            trimToCapacity: 75,
            maximumCapacity: 200,
            recentAccessProtectionInterval: 60
        )
        let plan = policy.evictionPlan(
            currentCapacity: 210,
            candidates: [
                .init(
                    id: "old",
                    capacity: 100,
                    lastAccessDate: now.addingTimeInterval(-120)
                ),
                .init(
                    id: "recent",
                    capacity: 110,
                    lastAccessDate: now.addingTimeInterval(-5)
                ),
            ],
            at: now
        )

        XCTAssertEqual(plan.evictions.map(\.id), ["old", "recent"])
        XCTAssertEqual(plan.projectedCapacity, 0)
        XCTAssertEqual(plan.protectedEntryCount, 0)
        XCTAssertEqual(plan.protectedCapacity, 0)
        XCTAssertTrue(plan.didExceedMaximumCapacity)
    }

    func testCallerCanExplicitlyIgnoreRecentAccessProtection()
    {
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        let policy = CacheCapacityPolicy.soft(
            preferredCapacity: 100,
            trimToCapacity: 75,
            maximumCapacity: 200,
            recentAccessProtectionInterval: 60
        )
        let plan = policy.evictionPlan(
            currentCapacity: 150,
            candidates: [
                .init(
                    id: "old",
                    capacity: 70,
                    lastAccessDate: now.addingTimeInterval(-120)
                ),
                .init(
                    id: "recent",
                    capacity: 80,
                    lastAccessDate: now.addingTimeInterval(-5)
                ),
            ],
            at: now,
            allowsProtectedEviction: true
        )

        XCTAssertEqual(plan.evictions.map(\.id), ["old", "recent"])
        XCTAssertEqual(plan.projectedCapacity, 0)
    }

    func testEqualAccessDatesRetainCandidateOrder()
    {
        let date = Date(timeIntervalSinceReferenceDate: 10_000)
        let policy = CacheCapacityPolicy.hard(
            maximumCapacity: 100,
            trimToCapacity: 50
        )
        let plan = policy.evictionPlan(
            currentCapacity: 150,
            candidates: [
                .init(id: "first", capacity: 50, lastAccessDate: date),
                .init(id: "second", capacity: 50, lastAccessDate: date),
                .init(id: "third", capacity: 50, lastAccessDate: date),
            ],
            at: date
        )

        XCTAssertEqual(plan.evictions.map(\.id), ["first", "second"])
        XCTAssertEqual(plan.projectedCapacity, 50)
    }

    func testUnlimitedPolicyDoesNotEvictOrRejectEntries()
    {
        let policy = CacheCapacityPolicy.unlimited
        let plan = policy.evictionPlan(
            currentCapacity: .max,
            candidates: [
                CacheCapacityPolicy.Candidate(
                    id: 1,
                    capacity: .max,
                    lastAccessDate: .distantPast
                ),
            ]
        )

        XCTAssertTrue(policy.allowsEntry(capacity: .max))
        XCTAssertTrue(plan.evictions.isEmpty)
        XCTAssertEqual(plan.projectedCapacity, .max)
    }

    func testZeroCapacityCandidatesAreNeverEvicted()
    {
        let policy = CacheCapacityPolicy.hard(
            maximumCapacity: 1,
            trimToCapacity: 0
        )
        let plan = policy.evictionPlan(
            currentCapacity: 2,
            candidates: [
                .init(
                    id: "metadata-only",
                    capacity: 0,
                    lastAccessDate: .distantPast
                ),
            ]
        )

        XCTAssertTrue(plan.evictions.isEmpty)
        XCTAssertEqual(plan.projectedCapacity, 2)
    }

    func testCustomStoreCanReuseCapacityPlanningAndReportCustomUnits() async throws
    {
        let policy = CacheCapacityPolicy.hard(
            maximumCapacity: 2,
            trimToCapacity: 1
        )
        let store = CacheStore<String, Int>(
            id: "custom",
            retrieve: { _ in nil },
            store: { _, _ in },
            remove: { _ in },
            removeAll: {},
            maintenance: { _ in
                let plan = policy.evictionPlan(
                    currentCapacity: 3,
                    candidates: [
                        CacheCapacityPolicy.Candidate(
                            id: "first",
                            capacity: 1,
                            lastAccessDate: .distantPast
                        ),
                        CacheCapacityPolicy.Candidate(
                            id: "second",
                            capacity: 1,
                            lastAccessDate: .distantPast
                        ),
                        CacheCapacityPolicy.Candidate(
                            id: "third",
                            capacity: 1,
                            lastAccessDate: .distantPast
                        ),
                    ]
                )
                return CacheStoreMaintenanceResult(
                    status: .completed,
                    scannedEntryCount: 3,
                    removedEntryCount: plan.evictions.count,
                    capacityUnit: .entries,
                    removedCapacity: plan.evictions.reduce(0) {
                        $0 + $1.capacity
                    },
                    remainingEntryCount: Int(plan.projectedCapacity),
                    remainingCapacity: plan.projectedCapacity,
                    didExceedMaximumCapacity:
                        plan.didExceedMaximumCapacity
                )
            }
        )
        let cache = try Cache(stores: [store])

        let report = try await cache.performMaintenance()
        let result = try XCTUnwrap(report[storeID: "custom"])

        XCTAssertEqual(result.capacityUnit, .entries)
        XCTAssertEqual(result.removedEntryCount, 2)
        XCTAssertEqual(result.removedCapacity, 2)
        XCTAssertEqual(result.remainingCapacity, 1)
        XCTAssertTrue(result.didExceedMaximumCapacity)
    }
}
