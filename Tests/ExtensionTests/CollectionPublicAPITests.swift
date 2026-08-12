//
//  CollectionPublicAPITests.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import XCTest
import SwiftExtension

final class CollectionPublicAPITests: XCTestCase {
    func testStackUsesLastInFirstOutOrdering() {
        var stack: Stack<Int> = [1, 2]

        stack.push(3)

        XCTAssertEqual(stack.peek(), 3)
        XCTAssertEqual(stack.pop(), 3)
        XCTAssertEqual(stack.pop(), 2)
        XCTAssertFalse(stack.isEmpty)
        XCTAssertEqual(stack.pop(), 1)
        XCTAssertTrue(stack.isEmpty)
    }

    func testQueueUsesFirstInFirstOutOrdering() {
        var queue = Queue<Int>()
        [1, 2, 3].forEach { queue.enqueue($0) }

        XCTAssertEqual(queue.peek(), 1)
        XCTAssertEqual(queue.dequeue(), 1)
        XCTAssertEqual(queue.dequeue(), 2)
        XCTAssertEqual(queue.dequeue(), 3)
        XCTAssertNil(queue.dequeue())
        XCTAssertTrue(queue.isEmpty)
    }

    func testFastQueueMaintainsCountWhileCompactingStorage() {
        var queue = FastQueue<Int>()
        (0..<100).forEach { queue.enqueue($0) }

        let firstSixty = (0..<60).map { _ in queue.dequeue() }

        XCTAssertEqual(firstSixty, (0..<60).map(Optional.some))
        XCTAssertEqual(queue.count, 40)
        XCTAssertEqual(queue.peek(), 60)
    }

    func testHeapRemovesValuesInPriorityOrder() {
        var heap = Heap(array: [4, 1, 5, 2, 3], sort: <)
        var removed: [Int] = []

        while let value = heap.remove() {
            removed.append(value)
        }

        XCTAssertEqual(removed, [1, 2, 3, 4, 5])
    }

    func testPriorityQueueExposesHeapOrderingAsAQueue() {
        var queue = PriorityQueue<Int>(sort: >)
        [4, 1, 5, 2, 3].forEach { queue.enqueue($0) }

        XCTAssertEqual(queue.peek(), 5)
        XCTAssertEqual((0..<5).compactMap { _ in queue.dequeue() }, [5, 4, 3, 2, 1])
        XCTAssertTrue(queue.isEmpty)
    }

    func testHashedHeapKeepsUniqueValueIndicesInSync() {
        var heap = HashedHeap(array: [4, 1, 5, 2, 3], sort: <)

        assertIndicesMatchElements(heap)
        XCTAssertEqual(heap.remove(), 1)
        assertIndicesMatchElements(heap)
        heap.insert(0)
        assertIndicesMatchElements(heap)
        XCTAssertEqual(heap.peek(), 0)
    }

    func testHashedHeapTreatsDuplicateInsertionsAsNoOps() {
        var heap = HashedHeap(array: [3, 1, 2, 1], sort: <)

        XCTAssertEqual(heap.count, 3)
        XCTAssertEqual(Set(heap.elements), Set([1, 2, 3]))

        heap.insert(2)

        XCTAssertEqual(heap.count, 3)
        assertIndicesMatchElements(heap)
    }

    func testHashedHeapMutationsKeepIndicesAndOrderingInSync() {
        var heap = HashedHeap<Int>(sort: <)
        heap.insert([8, 3, 5, 1, 6, 2, 7, 4])
        assertIndicesMatchElements(heap)

        XCTAssertEqual(heap.remove(at: 3).map { _ in heap.count }, 7)
        assertIndicesMatchElements(heap)

        if let index = heap.index(of: 6) {
            heap.replace(0, at: index)
        }
        assertIndicesMatchElements(heap)

        var drained: [Int] = []
        while let value = heap.remove() {
            drained.append(value)
            assertIndicesMatchElements(heap)
        }
        XCTAssertEqual(drained, drained.sorted())
    }

    func testHashedHeapMaintainsAllInvariantsAcrossDeterministicStressOperations() {
        var heap = HashedHeap<Int>(sort: <)
        var expected = Set<Int>()
        var randomState: UInt64 = 0xC0FFEE

        func nextRandom() -> UInt64 {
            randomState = randomState &* 6_364_136_223_846_793_005 &+ 1
            return randomState
        }

        for step in 0..<2_000 {
            switch nextRandom() % 4 {
            case 0:
                let value = Int(nextRandom() % 256)
                heap.insert(value)
                expected.insert(value)
            case 1:
                XCTAssertEqual(heap.remove(), expected.min())
                if let minimum = expected.min() {
                    expected.remove(minimum)
                }
            case 2 where !heap.isEmpty:
                let index = Int(nextRandom() % UInt64(heap.count))
                let value = heap.elements[index]
                XCTAssertEqual(heap.remove(at: index), value)
                expected.remove(value)
            case 3 where !heap.isEmpty:
                let index = Int(nextRandom() % UInt64(heap.count))
                let oldValue = heap.elements[index]
                let newValue = 10_000 + step
                heap.replace(newValue, at: index)
                expected.remove(oldValue)
                expected.insert(newValue)
            default:
                break
            }

            assertIndicesMatchElements(heap)
            XCTAssertEqual(Set(heap.elements), expected)
            assertMinHeapOrdering(heap)
        }
    }

    func testArrayChunkingAndSafeRangesExposeBoundaryBehavior() {
        let values = [0, 1, 2, 3, 4]

        XCTAssertEqual(values.chunked(into: 2), [[0, 1], [2, 3], [4]])
        XCTAssertEqual(Array(values[safe: -2..<2]), [0, 1])
        XCTAssertEqual(Array(values[safe: 3..<10]), [3, 4])
        XCTAssertEqual(Array(values[safe: 10..<12]), [])
    }

    private func assertIndicesMatchElements<T: Hashable>(
        _ heap: HashedHeap<T>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(heap.indices.count, heap.elements.count, file: file, line: line)
        for (index, element) in heap.elements.enumerated() {
            XCTAssertEqual(heap.index(of: element), index, file: file, line: line)
        }
    }

    private func assertMinHeapOrdering(
        _ heap: HashedHeap<Int>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for child in heap.elements.indices.dropFirst() {
            let parent = (child - 1) / 2
            XCTAssertLessThanOrEqual(
                heap.elements[parent],
                heap.elements[child],
                file: file,
                line: line
            )
        }
    }
}
