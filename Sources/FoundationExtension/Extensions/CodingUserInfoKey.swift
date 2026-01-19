//
//  CodingUserInfoKey.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

public extension CodingUserInfoKey
{
    static let lossyReporter = CodingUserInfoKey(rawValue: "com.zeewanderer.extension.lossyReporter")!
    static let decoderInstanceID = CodingUserInfoKey(rawValue: "com.zeewanderer.extension.decoderInstanceID")!
    static let decoderSentinel = CodingUserInfoKey(rawValue: "com.zeewanderer.extension.decoderSentinel")!
}
