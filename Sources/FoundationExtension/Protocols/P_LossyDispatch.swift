//
//  P_LossyDispatch.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

@usableFromInline
internal protocol P_LossyArrayDispatch
{
    static func _decodeArray(from decoder: Decoder, reporter: LossyDecodingReporter) throws -> Any
    static func _encodeArray(_ value: Any, to encoder: Encoder) throws
    static func _defaultArray() -> Any
}

@usableFromInline
internal protocol P_LossyOptionalDispatch
{
    static func _decodeOptional(from decoder: Decoder, reporter: LossyDecodingReporter) throws -> Any
    static func _encodeOptional(_ value: Any, to encoder: Encoder) throws
    static func _defaultOptional() -> Any
}
