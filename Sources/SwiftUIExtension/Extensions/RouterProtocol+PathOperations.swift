//
//  RouterProtocol+PathOperations.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

public extension RouterProtocol
{
    @discardableResult
    static func popAll(_ path: inout [Destination]) -> Bool
    {
        path.removeAll(keepingCapacity: true)
        return true
    }

    @discardableResult
    static func pop(_ path: inout [Destination], amount: Int = 1) -> Bool
    {
        guard amount >= 0, amount <= path.count else { return false }
        path.removeLast(amount)
        return true
    }

    @discardableResult
    static func pop(
        _ path: inout [Destination],
        to destination: Destination
    ) -> Bool
    {
        guard let index = path.lastIndex(of: destination) else { return false }
        path.removeSubrange(path.index(after: index)..<path.endIndex)
        return true
    }

    @discardableResult
    static func pop(
        _ path: inout [Destination],
        toFlat destination: Destination.Flat
    ) -> Bool
    {
        guard let index = lastIndex(path, ofFlat: destination) else { return false }
        path.removeSubrange(path.index(after: index)..<path.endIndex)
        return true
    }

    static func contains(
        _ path: [Destination],
        destination: Destination
    ) -> Bool
    {
        path.contains(destination)
    }

    static func contains(
        _ path: [Destination],
        flat: Destination.Flat
    ) -> Bool
    {
        path.contains { $0.flat == flat }
    }

    static func firstIndex(
        _ path: [Destination],
        of destination: Destination
    ) -> Int?
    {
        path.firstIndex(of: destination)
    }

    static func firstIndex(
        _ path: [Destination],
        ofFlat destination: Destination.Flat
    ) -> Int?
    {
        path.firstIndex { $0.flat == destination }
    }

    static func lastIndex(
        _ path: [Destination],
        of destination: Destination
    ) -> Int?
    {
        path.lastIndex(of: destination)
    }

    static func lastIndex(
        _ path: [Destination],
        ofFlat destination: Destination.Flat
    ) -> Int?
    {
        path.lastIndex { $0.flat == destination }
    }

    static func peek(_ path: [Destination]) -> Destination?
    {
        path.last
    }

    static func peek(
        _ path: [Destination],
        flat: Destination.Flat,
        search: RouterPathSearchDirection = .last
    ) -> Destination?
    {
        let index: Int?
        switch search
        {
        case .first:
            index = firstIndex(path, ofFlat: flat)
        case .last:
            index = lastIndex(path, ofFlat: flat)
        }
        return index.map { path[$0] }
    }

    @discardableResult
    static func replace(
        _ path: inout [Destination],
        destination: Destination,
        with replacement: Destination,
        search: RouterPathSearchDirection = .last
    ) -> Bool
    {
        let index: Int?
        switch search
        {
        case .first:
            index = firstIndex(path, of: destination)
        case .last:
            index = lastIndex(path, of: destination)
        }

        guard let index else { return false }
        path[index] = replacement
        return true
    }

    @discardableResult
    static func replace(
        _ path: inout [Destination],
        flat: Destination.Flat,
        with replacement: Destination,
        search: RouterPathSearchDirection = .last
    ) -> Bool
    {
        let index: Int?
        switch search
        {
        case .first:
            index = firstIndex(path, ofFlat: flat)
        case .last:
            index = lastIndex(path, ofFlat: flat)
        }

        guard let index else { return false }
        path[index] = replacement
        return true
    }

    @discardableResult
    static func push(
        _ destination: Destination,
        to path: inout [Destination],
        options: RouterPushOptions = []
    ) -> Bool
    {
        if options.contains(.popToExisting)
        {
            if options.contains(.flatComparison),
               pop(&path, toFlat: destination.flat)
            {
                return true
            }

            if !options.contains(.flatComparison),
               pop(&path, to: destination)
            {
                return true
            }
        }

        path.append(destination)
        return true
    }
}
