//
//  P_LossyInspect.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

@usableFromInline
internal struct P_LossyInspect
{
    private init() {}
    
    @usableFromInline
    static func rawString(from decoder: Decoder) -> String?
    {
        if let s = try? decoder.singleValueContainer()
        {
            if s.decodeNil() { return "null" }
            if let v = try? s.decode(String.self) { return quote(v) }
            if let v = try? s.decode(Bool.self) { return v ? "true" : "false" }
            if let v = try? s.decode(Int64.self) { return String(v) }
            if let v = try? s.decode(UInt64.self) { return String(v) }
            if let v = try? s.decode(Decimal.self) { return NSDecimalNumber(decimal: v).stringValue }
            if let v = try? s.decode(Double.self) { return String(v) }
        }
        if var u = try? decoder.unkeyedContainer()
        {
            var parts: [String] = []
            while !u.isAtEnd
            {
                if let sub = try? u.superDecoder()
                { parts.append(rawString(from: sub) ?? "null") }
                else
                {
                    parts.append("null")
                    _ = try? u.superDecoder()
                }
            }
            return "[\(parts.joined(separator: ","))]"
        }
        if let k = try? decoder.container(keyedBy: AnyCodingKey.self)
        {
            var parts: [String] = []
            for key in k.allKeys
            {
                let ks = quote(key.stringValue)
                if let sub = try? k.superDecoder(forKey: key)
                {
                    let val = rawString(from: sub) ?? "null"
                    parts.append("\(ks):\(val)")
                } else { parts.append("\(ks):null") }
            }
            return "{\(parts.joined(separator: ","))}"
        }
        return nil
    }
    
    private static func quote(_ s: String) -> String
    {
        var out = "\""
        out.reserveCapacity(s.count + 2)
        for u in s.unicodeScalars
        {
            switch u.value {
            case 0x22: out += "\\\""
            case 0x5C: out += "\\\\"
            case 0x08: out += "\\b"
            case 0x0C: out += "\\f"
            case 0x0A: out += "\\n"
            case 0x0D: out += "\\r"
            case 0x09: out += "\\t"
            case 0x00...0x1F:
                let hex = String(format: "%04X", u.value)
                out += "\\u\(hex)"
            default:
                out.unicodeScalars.append(u)
            }
        }
        out += "\""
        return out
    }
    
    @usableFromInline
    static func codingPath(_ error: Error, from decoder: Decoder) -> [CodingKey]
    {
        guard let decodingError = error as? DecodingError else { return decoder.codingPath }
        
        switch decodingError {
        case .keyNotFound(let codingKey, let context):
            return context.codingPath + [codingKey]
        case .dataCorrupted(let context):
            return context.codingPath
        case .valueNotFound(_, let context):
            return context.codingPath
        case .typeMismatch(_, let context):
            return context.codingPath
        @unknown default:
            return decoder.codingPath
        }
    }
}
