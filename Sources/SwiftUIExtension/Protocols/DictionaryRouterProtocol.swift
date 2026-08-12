//
//  DictionaryRouterProtocol.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// A router backed by navigation paths keyed by ``RouterProtocol/PathID``.
@MainActor
public protocol DictionaryRouterProtocol: RouterProtocol
{
    var paths: [PathID: [Destination]] { get set }
}

public extension DictionaryRouterProtocol
{
    /// The currently resolved default path.
    var path: [Destination]
    {
        get
        {
            guard let pathID = resolvePathID(nil) else { return [] }
            return path(for: pathID)
        }
        set
        {
            guard let pathID = resolvePathID(nil) else { return }
            withPath(pathID) { $0 = newValue }
        }
    }

    func path(for pathID: PathID) -> [Destination]
    {
        paths[pathID, default: []]
    }

    @discardableResult
    func withPath(
        _ pathID: PathID,
        _ mutation: (inout [Destination]) -> Void
    ) -> Bool
    {
        mutation(&paths[pathID, default: []])
        return true
    }
}
