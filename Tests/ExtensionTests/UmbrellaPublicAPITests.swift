//
//  UmbrellaPublicAPITests.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import XCTest
import Extension

final class UmbrellaPublicAPITests: XCTestCase {
    func testUmbrellaModuleReexportsRepresentativePublicAPIs() {
        let pair = Pair("answer", 42)
        let dictionary: [String: Int] = makeDictionary {
            ["one": 1]
            ["two": 2]
        }
        var queue = FastQueue<Int>()
        queue.enqueue(42)
        let convolution = vDSP.fullConvolution(
            [Float(1), 2, 3],
            withKernel: [Float(1), 1]
        )
        let observations = ObservationsCompat { 42 }

        XCTAssertEqual(pair, Pair("answer", 42))
        XCTAssertEqual(dictionary, ["one": 1, "two": 2])
        XCTAssertEqual(queue.dequeue(), 42)
        XCTAssertEqual(clamp(12, to: 0...10), 10)
        XCTAssertEqual(UInt32(data: UInt32(42).data), 42)
        XCTAssertEqual(convolution, [1, 3, 5, 3])
        _ = observations.makeAsyncIterator()
    }
}
