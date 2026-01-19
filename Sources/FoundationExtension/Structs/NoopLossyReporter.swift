//
//  NoopLossyReporter.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

public struct NoopLossyReporter: LossyDecodingReporter
{
    @inlinable
    @inline(__always)
    public init() {}
    
    @inlinable
    @inline(__always)
    public func recordLoss(raw: String?, codingPath: [CodingKey], message: String, underlying: Error?) {}
}
