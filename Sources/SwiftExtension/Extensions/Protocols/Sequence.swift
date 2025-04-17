//
//  Sequence.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

public extension Sequence
{
    /// - Warning: Will be removed when problems with [SE-0220](https://github.com/apple/swift-evolution/blob/main/proposals/0220-count-where.md) are resolved.
    @inlinable
    func count(where condition: (Self.Element) throws -> Bool) rethrows -> Int
    {
        return try self.lazy.filter(condition).count
    }
}
