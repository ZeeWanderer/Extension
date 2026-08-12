//
//  RouterProtocol+PathQueries.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

public extension RouterProtocol
{
    func contains(
        _ destination: Destination,
        on pathID: PathID?
    ) -> Bool
    {
        resolvedPath(for: pathID).map {
            Self.contains($0, destination: destination)
        } ?? false
    }

    func contains(
        flat: Destination.Flat,
        on pathID: PathID?
    ) -> Bool
    {
        resolvedPath(for: pathID).map {
            Self.contains($0, flat: flat)
        } ?? false
    }

    func firstIndex(
        of destination: Destination,
        on pathID: PathID?
    ) -> Int?
    {
        resolvedPath(for: pathID).flatMap {
            Self.firstIndex($0, of: destination)
        }
    }

    func firstIndex(
        ofFlat flat: Destination.Flat,
        on pathID: PathID?
    ) -> Int?
    {
        resolvedPath(for: pathID).flatMap {
            Self.firstIndex($0, ofFlat: flat)
        }
    }

    func lastIndex(
        of destination: Destination,
        on pathID: PathID?
    ) -> Int?
    {
        resolvedPath(for: pathID).flatMap {
            Self.lastIndex($0, of: destination)
        }
    }

    func lastIndex(
        ofFlat flat: Destination.Flat,
        on pathID: PathID?
    ) -> Int?
    {
        resolvedPath(for: pathID).flatMap {
            Self.lastIndex($0, ofFlat: flat)
        }
    }

    func peek(on pathID: PathID?) -> Destination?
    {
        guard let path = resolvedPath(for: pathID) else { return nil }
        return Self.peek(path)
    }

    func peek(
        flat: Destination.Flat,
        on pathID: PathID?,
        search: RouterPathSearchDirection
    ) -> Destination?
    {
        resolvedPath(for: pathID).flatMap {
            Self.peek($0, flat: flat, search: search)
        }
    }

    func contains(_ destination: Destination) -> Bool
    {
        contains(destination, on: Optional<PathID>.none)
    }

    func contains(flat: Destination.Flat) -> Bool
    {
        contains(flat: flat, on: Optional<PathID>.none)
    }

    func firstIndex(of destination: Destination) -> Int?
    {
        firstIndex(of: destination, on: Optional<PathID>.none)
    }

    func firstIndex(ofFlat flat: Destination.Flat) -> Int?
    {
        firstIndex(ofFlat: flat, on: Optional<PathID>.none)
    }

    func lastIndex(of destination: Destination) -> Int?
    {
        lastIndex(of: destination, on: Optional<PathID>.none)
    }

    func lastIndex(ofFlat flat: Destination.Flat) -> Int?
    {
        lastIndex(ofFlat: flat, on: Optional<PathID>.none)
    }

    func peek() -> Destination?
    {
        peek(on: Optional<PathID>.none)
    }

    func peek(
        flat: Destination.Flat,
        search: RouterPathSearchDirection = .last
    ) -> Destination?
    {
        peek(flat: flat, on: Optional<PathID>.none, search: search)
    }
}

private extension RouterProtocol
{
    func resolvedPath(for requestedPathID: PathID?) -> [Destination]?
    {
        guard let pathID = resolvePathID(requestedPathID) else { return nil }
        return path(for: pathID)
    }
}
