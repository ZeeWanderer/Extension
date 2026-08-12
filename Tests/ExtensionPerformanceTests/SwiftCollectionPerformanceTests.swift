//
//  SwiftCollectionPerformanceTests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import XCTest
import SwiftExtension

final class SwiftCollectionPerformanceTests: ReleasePerformanceTestCase
{
    func testFastQueueThroughputPerformance()
    {
        let elementCount = 250_000
        let repetitions = 20
        var checksum = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions) {
            var measuredChecksum = 0
            for _ in 0..<repetitions {
                var queue = FastQueue<Int>()
                for value in 0..<elementCount {
                    queue.enqueue(value)
                }
                while let value = queue.dequeue() {
                    measuredChecksum &+= value
                }
            }
            checksum = measuredChecksum
        }

        XCTAssertEqual(checksum, (0..<elementCount).reduce(0, &+) * repetitions)
    }

    func testLinkedListQueueThroughputPerformance()
    {
        let elementCount = 100_000
        let repetitions = 3
        var checksum = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions) {
            var measuredChecksum = 0
            for _ in 0..<repetitions {
                var queue = Queue<Int>()
                for value in 0..<elementCount {
                    queue.enqueue(value)
                }
                while let value = queue.dequeue() {
                    measuredChecksum &+= value
                }
            }
            checksum = measuredChecksum
        }

        XCTAssertEqual(checksum, (0..<elementCount).reduce(0, &+) * repetitions)
    }

    func testQueueCopyOnWriteMutationPerformance()
    {
        let elementCount = 100_000
        var original = Queue<Int>()
        for value in 0..<elementCount {
            original.enqueue(value)
        }
        var copiedCount = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions) {
            var copy = original
            copy.enqueue(elementCount)
            var count = 0
            while copy.dequeue() != nil {
                count += 1
            }
            copiedCount = count
        }

        XCTAssertEqual(copiedCount, elementCount + 1)
        XCTAssertEqual(original.peek(), 0)
        while original.dequeue() != nil {}
    }

    func testHashedHeapBuildAndDrainPerformance()
    {
        let values = Array((0..<100_000).reversed())
        var removedCount = 0

        measure(metrics: [XCTCPUMetric()], options: measurementOptions) {
            var heap = HashedHeap(array: values, sort: <)
            var count = 0
            while heap.remove() != nil {
                count += 1
            }
            removedCount = count
        }

        XCTAssertEqual(removedCount, values.count)
    }
}
