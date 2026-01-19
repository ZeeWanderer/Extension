//
//  Optional+P_LossyOptionalDispatch.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

extension Optional: P_LossyOptionalDispatch where Wrapped: Codable
{
    @usableFromInline
    static func _decodeOptional(from decoder: Decoder, reporter: LossyDecodingReporter) throws -> Any
    {
        let s = try decoder.singleValueContainer()
        if s.decodeNil() { return Self.none as Any }
        
        if let arr = Wrapped.self as? P_LossyArrayDispatch.Type {
            do { return try arr._decodeArray(from: decoder, reporter: reporter) as! Wrapped }
            catch
            {
                let path = P_LossyInspect.codingPath(error, from: decoder)
                let raw = P_LossyInspect.rawString(from: decoder)
                reporter.recordLoss(
                    raw: raw,
                    codingPath: path,
                    message: "Expected array but found incompatible value; set optional array to nil",
                    underlying: error
                )
                return Self.none as Any
            }
        }
        
        do { return try s.decode(Wrapped.self) }
        catch
        {
            let path = P_LossyInspect.codingPath(error, from: decoder)
            let raw = P_LossyInspect.rawString(from: decoder)
            reporter.recordLoss(
                raw: raw,
                codingPath: path,
                message: "Set optional to nil due to invalid value",
                underlying: error
            )
            return Self.none as Any
        }
    }
    
    @usableFromInline
    static func _encodeOptional(_ value: Any, to encoder: Encoder) throws
    {
        let v = value as! Self
        var c = encoder.singleValueContainer()
        try c.encode(v)
    }
    
    @usableFromInline
    static func _defaultOptional() -> Any
    { Self.none as Any }
}
