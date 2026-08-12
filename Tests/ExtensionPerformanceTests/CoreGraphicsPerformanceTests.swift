//
//  CoreGraphicsPerformanceTests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import CoreGraphics
import XCTest
import CoreGraphicsExtension

final class CoreGraphicsPerformanceTests: ReleasePerformanceTestCase
{
    func testLargeRectangleUnionPerformance()
    {
        let rectangles = (0..<100_000).map { index in
            CGRect(
                x: CGFloat(index % 1_000),
                y: CGFloat(index / 1_000),
                width: 10,
                height: 10
            )
        }
        let repetitions = 100
        var result = CGRect.null
        var widthChecksum: CGFloat = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions) {
            var measuredWidth: CGFloat = 0
            for _ in 0..<repetitions {
                result = union(rectangles)
                measuredWidth += result.width
            }
            widthChecksum = measuredWidth
        }

        XCTAssertEqual(result, CGRect(x: 0, y: 0, width: 1_009, height: 109))
        XCTAssertEqual(widthChecksum, result.width * CGFloat(repetitions))
    }

    func testNumeric2DArithmeticPerformance()
    {
        let points = (0..<250_000).map { index in
            CGPoint(x: CGFloat(index), y: CGFloat(index % 997))
        }
        let scale = CGSize(width: 1.25, height: 0.75)
        let repetitions = 100
        var checksum: CGFloat = 0

        measure(metrics: [XCTClockMetric()], options: measurementOptions) {
            var value: CGFloat = 0
            for _ in 0..<repetitions {
                for point in points {
                    value += point.hadamard(scale).dot(point)
                }
            }
            checksum = value
        }

        XCTAssertGreaterThan(checksum, 0)
    }
}
