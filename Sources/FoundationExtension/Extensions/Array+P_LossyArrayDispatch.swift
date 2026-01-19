//
//  Array+P_LossyArrayDispatch.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

extension Array: P_LossyArrayDispatch where Element: Codable
{
    @usableFromInline
    static func _decodeArray(from decoder: Decoder, reporter: LossyDecodingReporter) throws -> Any
    {
        var out: [Element] = []
        var c = try decoder.unkeyedContainer()
        var i = 0
        
        while !c.isAtEnd {
            do { out.append(try c.decode(Element.self)) }
            catch
            {
                let sub = try? c.superDecoder()
                let path = P_LossyInspect.codingPath(error, from: decoder)
                let raw = sub.flatMap { P_LossyInspect.rawString(from: $0) }
                reporter.recordLoss(
                    raw: raw,
                    codingPath: path,
                    message: "Dropped invalid array element at Index \(i)",
                    underlying: error
                )
            }
            i += 1
        }
        
        return out
    }
    
    @usableFromInline
    static func _encodeArray(_ value: Any, to encoder: Encoder) throws
    {
        let arr = value as! Self
        var c = encoder.unkeyedContainer()
        for v in arr { try c.encode(v) }
    }
    
    @usableFromInline
    static func _defaultArray() -> Any
    { [] as Self }
}
