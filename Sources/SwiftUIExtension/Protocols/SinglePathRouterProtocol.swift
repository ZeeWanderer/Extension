//
//  SinglePathRouterProtocol.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// A router backed by one navigation path.
@MainActor
public protocol SinglePathRouterProtocol: RouterProtocol
where PathID == RouterSinglePathID
{
    var path: [Destination] { get set }
}

public extension SinglePathRouterProtocol
{
    static var defaultPathID: PathID? { .main }

    func path(for pathID: PathID) -> [Destination]
    {
        path
    }

    @discardableResult
    func withPath(
        _ pathID: PathID,
        _ mutation: (inout [Destination]) -> Void
    ) -> Bool
    {
        mutation(&path)
        return true
    }
}
