//
//  SparseCacheConcurrencyTests.swift
//
//
//  Created by zeewanderer on 10.09.2026.
//

import Foundation
import XCTest
@testable import FoundationExtension

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@MainActor
final class SparseCacheConcurrencyTests: XCTestCase
{
    func testConcurrentImmediateFlushesPersistEveryCompletedRange() async throws
    {
        let cache = try p_makeCache(flushDelay: .zero)
        let offsets = Array(stride(from: 0, to: 128, by: 2))
        let expectedRanges = offsets.map { $0..<($0 + 1) }

        for iteration in 0..<8
        {
            let key = "resource-\(iteration)"
            _ = try await cache.prepare(capacity: 128, forKey: key)

            try await withThrowingTaskGroup(of: Void.self) { group in
                for offset in offsets
                {
                    group.addTask {
                        _ = try await cache.insert(
                            Data([UInt8(offset)]),
                            at: offset,
                            forKey: key
                        )
                    }
                }
                try await group.waitForAll()
            }

            // Do not synchronize: that would mask lost background flushes.
            try await p_expectPersistedRanges(expectedRanges, forKey: key, in: cache)
        }
    }

    func testManifestPersistenceOutlivesTheCancelledWritingTask() async throws
    {
        let cache = try p_makeCache(flushDelay: .milliseconds(50))
        _ = try await cache.prepare(capacity: 8, forKey: "resource")

        try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                _ = try await cache.insert(Data([1, 2, 3]), at: 2, forKey: "resource")
                withUnsafeCurrentTask { $0?.cancel() }
                return Task.isCancelled
            }
            let wasCancelled = try await group.next()
            XCTAssertEqual(wasCancelled, true)
        }

        try await p_expectPersistedRanges([2..<5], forKey: "resource", in: cache)
    }

    func p_makeCache(flushDelay: Duration) throws -> SparseCache<String>
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let storage = try DiskCacheStorage(
            name: "persistence-tests",
            location: .custom(root),
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        return try SparseCache(
            storage: storage,
            configuration: .init(manifestFlushDelay: flushDelay)
        )
    }

    func p_expectPersistedRanges(
        _ ranges: [Range<Int>],
        forKey key: String,
        in cache: SparseCache<String>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws
    {
        let url = try cache.p_fileURLs(for: key).manifest
        let deadline = ContinuousClock.now.advanced(by: .seconds(3))
        var persistedRanges: [Range<Int>] = []
        repeat
        {
            // Inspect the persisted manifest, not the in-process snapshot.
            let manifest = try JSONDecoder().decode(
                P_SparseCacheManifest.self,
                from: Data(contentsOf: url)
            )
            persistedRanges = manifest.ranges
            if persistedRanges == ranges { return }
            try await Task.sleep(for: .milliseconds(5))
        }
        while ContinuousClock.now < deadline

        XCTAssertEqual(persistedRanges, ranges, file: file, line: line)
    }
}
