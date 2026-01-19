//
//  JSONDecoder.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

public extension JSONDecoder
{
    @usableFromInline
    internal enum JSONDecoder_dict_decoding: CodingKey
    {
        case self_
    }
    
    @inlinable
    func decode<K, V, R>(_ type: [K:V].Type, from data: Data) throws -> [K:V]
    where K: RawRepresentable, K: Decodable, K.RawValue == R,
          V: Decodable,
          R: Decodable, R: Hashable
    {
        let rawDictionary = try self.decode([R: V].self, from: data)
        var dictionary = [K: V]()
        
        for (key, value) in rawDictionary
        {
            guard let enumKey = K(rawValue: key) else
            {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [JSONDecoder_dict_decoding.self_],
                                                                        debugDescription: "Could not parse json key \(key) to a \(K.self) enum"))
            }
            
            dictionary[enumKey] = value
        }
        
        return dictionary
    }
    
    @inlinable
    func setLossyReporter(_ reporter: LossyDecodingReporter)
    {
        self.userInfo[.lossyReporter] = reporter
        self.userInfo[.decoderInstanceID] = UUID()
        self.userInfo[.decoderSentinel] = P_DecoderSentinel()
    }
}
