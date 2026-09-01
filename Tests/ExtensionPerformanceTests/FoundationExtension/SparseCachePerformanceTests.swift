//
//  SparseCachePerformanceTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class SparseCachePerformanceTests: ReleasePerformanceTestCase
{
    func testConcurrentDisjointRangeWritePerformance() throws
    {
        let root = try p_makeCachePerformanceDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let storage = try DiskCacheStorage(
            name: "sparse-write",
            location: .custom(root),
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try SparseCache<String>(storage: storage)
        let chunkCount = 256
        let chunkSize = 32 * 1024
        let capacity = chunkCount * chunkSize
        var generation = 0
        var availableByteCount = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            let measuredGeneration = generation
            generation += 1
            availableByteCount = p_waitForCacheResult {
                _ = try! await cache.prepare(
                    capacity: capacity,
                    generation: Data(String(measuredGeneration).utf8),
                    forKey: "video"
                )
                await withTaskGroup(of: Void.self) { group in
                    for chunk in 0..<chunkCount
                    {
                        group.addTask {
                            _ = try! await cache.insert(
                                Data(
                                    repeating: UInt8(truncatingIfNeeded: chunk),
                                    count: chunkSize
                                ),
                                at: chunk * chunkSize,
                                forKey: "video"
                            )
                        }
                    }
                    await group.waitForAll()
                }
                return try! await cache.snapshot(forKey: "video")?
                    .availableByteCount ?? 0
            }
        }

        XCTAssertEqual(availableByteCount, capacity)
    }

    func testConcurrentSparseRangeReadPerformance() throws
    {
        let root = try p_makeCachePerformanceDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let storage = try DiskCacheStorage(
            name: "sparse-read",
            location: .custom(root),
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try SparseCache<String>(storage: storage)
        let workerCount = 64
        let operationCount = 1_024
        let rangeSize = 16 * 1024
        let capacity = operationCount * rangeSize
        _ = try cache.prepare(capacity: capacity, forKey: "video")
        _ = try cache.insert(
            Data(repeating: 0xa5, count: capacity),
            at: 0,
            forKey: "video"
        )
        var readByteCount = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions)
        {
            readByteCount = p_waitForCacheResult {
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
                                let lowerBound = operation * rangeSize
                                result += try! await cache.data(
                                    in: lowerBound..<(lowerBound + rangeSize),
                                    forKey: "video"
                                )?.count ?? 0
                            }
                            return result
                        }
                    }

                    var result = 0
                    for await byteCount in group { result += byteCount }
                    return result
                }
            }
        }

        XCTAssertEqual(readByteCount, capacity)
    }
}
