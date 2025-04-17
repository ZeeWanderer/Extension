//
//  Pair.swift
//  Extension
//
//  Created by zeewanderer on 16.04.2025.
//

public struct Pair<T, U>
{
    public let first: T
    public let second: U
    
    public init(_ first: T, _ second: U)
    {
        self.first = first
        self.second = second
    }
}

extension Pair: Equatable where T: Equatable, U: Equatable {}
extension Pair: Hashable where T: Hashable, U: Hashable {}
extension Pair: Encodable where T: Encodable, U: Encodable {}
extension Pair: Decodable where T: Decodable, U: Decodable {}
extension Pair: Sendable where T: Sendable, U: Sendable {}
