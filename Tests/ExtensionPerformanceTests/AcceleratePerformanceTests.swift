//
//  AcceleratePerformanceTests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import XCTest
import AccelerateExtension

final class AcceleratePerformanceTests: ReleasePerformanceTestCase
{
    func testFullConvolutionPerformance()
    {
        let signal = (0..<1_000_000).map { Float($0 % 1_000) - 500 }
        let kernel = (0..<31).map { index in
            Float(index - 15) / 120
        }
        let repetitions = 3
        var checksum: Float = 0

        measure(metrics: [XCTCPUMetric()], options: measurementOptions) {
            var measuredChecksum: Float = 0
            for _ in 0..<repetitions {
                let result = vDSP.fullConvolution(signal, withKernel: kernel)
                measuredChecksum += result[15]
                measuredChecksum += result[result.count - 16]
            }
            checksum = measuredChecksum
        }

        XCTAssertTrue(checksum.isFinite)
        XCTAssertNotEqual(checksum, 0)
    }
}
