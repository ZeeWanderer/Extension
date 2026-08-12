//
//  vDSP+FullConvolution.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Accelerate

public extension vDSP
{
    /// Returns the full linear convolution of `signal` and `kernel`.
    ///
    /// Unlike `vDSP.convolve(_:withKernel:)`, this operation includes the
    /// partially overlapping values at both ends. The result contains
    /// `signal.count + kernel.count - 1` values. If either input is empty,
    /// the result is empty.
    static func fullConvolution<Signal, Kernel>(
        _ signal: Signal,
        withKernel kernel: Kernel
    ) -> [Float]
    where
        Signal: AccelerateBuffer,
        Kernel: AccelerateBuffer,
        Signal.Element == Float,
        Kernel.Element == Float
    {
        guard signal.count > 0, kernel.count > 0 else { return [] }

        let paddingCount = kernel.count - 1
        var paddedSignal = [Float]()
        paddedSignal.reserveCapacity(signal.count + (paddingCount * 2))
        paddedSignal.append(contentsOf: repeatElement(0, count: paddingCount))
        signal.withUnsafeBufferPointer {
            paddedSignal.append(contentsOf: $0)
        }
        paddedSignal.append(contentsOf: repeatElement(0, count: paddingCount))

        var result = [Float](
            repeating: 0,
            count: signal.count + kernel.count - 1
        )
        vDSP.convolve(paddedSignal, withKernel: kernel, result: &result)
        return result
    }

    /// Returns the full linear convolution of `signal` and `kernel`.
    ///
    /// Unlike `vDSP.convolve(_:withKernel:)`, this operation includes the
    /// partially overlapping values at both ends. The result contains
    /// `signal.count + kernel.count - 1` values. If either input is empty,
    /// the result is empty.
    static func fullConvolution<Signal, Kernel>(
        _ signal: Signal,
        withKernel kernel: Kernel
    ) -> [Double]
    where
        Signal: AccelerateBuffer,
        Kernel: AccelerateBuffer,
        Signal.Element == Double,
        Kernel.Element == Double
    {
        guard signal.count > 0, kernel.count > 0 else { return [] }

        let paddingCount = kernel.count - 1
        var paddedSignal = [Double]()
        paddedSignal.reserveCapacity(signal.count + (paddingCount * 2))
        paddedSignal.append(contentsOf: repeatElement(0, count: paddingCount))
        signal.withUnsafeBufferPointer {
            paddedSignal.append(contentsOf: $0)
        }
        paddedSignal.append(contentsOf: repeatElement(0, count: paddingCount))

        var result = [Double](
            repeating: 0,
            count: signal.count + kernel.count - 1
        )
        vDSP.convolve(paddedSignal, withKernel: kernel, result: &result)
        return result
    }
}
