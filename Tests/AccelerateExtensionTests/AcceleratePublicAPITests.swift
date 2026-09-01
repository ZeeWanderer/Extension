//
//  AcceleratePublicAPITests.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import XCTest
import AccelerateExtension

final class AcceleratePublicAPITests: XCTestCase {
    func testFoundationBinaryAPIIsReexportedForExistingImports() {
        let values: [UInt32] = [1, 2, 3]

        XCTAssertEqual(Array<UInt32>(validating: values.data), values)
    }

    func testFloatFullConvolutionIncludesBoundaryOverlaps() {
        let signal: [Float] = [1, 2, 3]
        let kernel: [Float] = [1, 1]

        XCTAssertEqual(
            vDSP.fullConvolution(signal, withKernel: kernel),
            [1, 3, 5, 3]
        )
    }

    func testDoubleFullConvolutionSupportsArraySlices() {
        let signal: [Double] = [99, 1, 2, 3, 99]
        let kernel: [Double] = [99, 2, -1, 99]

        XCTAssertEqual(
            vDSP.fullConvolution(signal[1...3], withKernel: kernel[1...2]),
            [2, 3, 4, -3]
        )
    }

    func testFullConvolutionSupportsAKernelLongerThanTheSignal() {
        XCTAssertEqual(
            vDSP.fullConvolution([2] as [Float], withKernel: [1, 2, 3]),
            [2, 4, 6]
        )
    }

    func testFullConvolutionReturnsEmptyForEitherEmptyInput() {
        XCTAssertEqual(
            vDSP.fullConvolution([] as [Float], withKernel: [1]),
            []
        )
        XCTAssertEqual(
            vDSP.fullConvolution([1] as [Double], withKernel: []),
            []
        )
    }
}
