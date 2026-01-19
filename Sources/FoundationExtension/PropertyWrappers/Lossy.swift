//
//  Lossy.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

@propertyWrapper
public struct Lossy<Wrapped: Codable>: Codable, Sendable where Wrapped: Sendable
{
    public var wrappedValue: Wrapped
    
    @inlinable
    public init(wrappedValue: Wrapped)
    { self.wrappedValue = wrappedValue }
    
    @inlinable
    public init<T>() where Wrapped == [T], T: Codable
    { self.wrappedValue = [] }
    
    @inlinable
    public init<T>() where Wrapped == Optional<T>, T: Codable
    { self.wrappedValue = nil }
    
    @inlinable
    public init<T>() where Wrapped == Optional<[T]>, T: Codable
    { self.wrappedValue = nil }
    
    @inlinable
    public init<T>(wrappedValue: Wrapped = []) where Wrapped == [T], T: Codable
    { self.wrappedValue = wrappedValue }
    
    @inlinable
    public init<T>(wrappedValue: Wrapped = nil) where Wrapped == Optional<T>, T: Codable
    { self.wrappedValue = wrappedValue }
    
    @inlinable
    public init(from decoder: Decoder) throws
    {
        let type = Wrapped.self
        let lossyReporter = decoder.lossyReporter
        
        if let opt = type as? P_LossyOptionalDispatch.Type {
            self.wrappedValue = try (opt._decodeOptional(from: decoder, reporter: lossyReporter) as! Wrapped)
            return
        }
        
        if let arr = type as? P_LossyArrayDispatch.Type {
            self.wrappedValue = try (arr._decodeArray(from: decoder, reporter: lossyReporter) as! Wrapped)
            return
        }
        
        do { self.wrappedValue = try Wrapped(from: decoder) }
        catch
        {
            let path = P_LossyInspect.codingPath(error, from: decoder)
            let raw = P_LossyInspect.rawString(from: decoder)
            decoder.lossyReporter.recordLoss(
                raw: raw,
                codingPath: path,
                message: "Failed to decode required value",
                underlying: error
            )
            throw error
        }
    }
    
    @inlinable
    public func encode(to encoder: Encoder) throws
    {
        let type = Wrapped.self
        
        if let opt = type as? P_LossyOptionalDispatch.Type
        {
            try opt._encodeOptional(wrappedValue, to: encoder)
            return
        }
        
        if let arr = type as? P_LossyArrayDispatch.Type
        {
            try arr._encodeArray(wrappedValue, to: encoder)
            return
        }
        
        try wrappedValue.encode(to: encoder)
    }
}
