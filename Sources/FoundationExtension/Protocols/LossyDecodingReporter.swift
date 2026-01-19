//
//  LossyDecodingReporter.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

public protocol LossyDecodingReporter: Sendable
{
    func recordLoss(raw: String?, codingPath: [CodingKey], message: String, underlying: Error?)
}
