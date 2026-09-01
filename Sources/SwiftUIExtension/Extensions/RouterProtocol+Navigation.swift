//
//  RouterProtocol+Navigation.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

public extension RouterProtocol
{
    @discardableResult
    func push(
        _ destination: Destination,
        to pathID: PathID?,
        options: RouterPushOptions
    ) -> PathID?
    {
        let operation = RouterNavigationOperation.push(destination, options: options)
        let result = p_performNavigation(operation, on: pathID) { path, resolvedPathID in
            if options.contains(.popToExisting),
               let root = rootDestination(
                   for: destination,
                   on: resolvedPathID
               )
            {
                let matchesRoot = options.contains(.flatComparison)
                    ? root.flat == destination.flat
                    : root == destination

                if matchesRoot
                {
                    return Self.popAll(&path)
                }
            }

            return Self.push(destination, to: &path, options: options)
        }
        return result.succeeded ? result.pathID : nil
    }

    @discardableResult
    func popAll(_ pathID: PathID?) -> Bool
    {
        p_performNavigation(.popAll, on: pathID) { path, _ in
            Self.popAll(&path)
        }.succeeded
    }

    @discardableResult
    func pop(_ pathID: PathID?, amount: Int) -> Bool
    {
        p_performNavigation(.pop(amount: amount), on: pathID) { path, _ in
            Self.pop(&path, amount: amount)
        }.succeeded
    }

    @discardableResult
    func pop(
        _ pathID: PathID?,
        to destination: Destination
    ) -> Bool
    {
        p_performNavigation(.popTo(destination), on: pathID) { path, _ in
            Self.pop(&path, to: destination)
        }.succeeded
    }

    @discardableResult
    func pop(
        _ pathID: PathID?,
        toFlat destination: Destination.Flat
    ) -> Bool
    {
        p_performNavigation(.popToFlat(destination), on: pathID) { path, _ in
            Self.pop(&path, toFlat: destination)
        }.succeeded
    }

    @discardableResult
    func replace(
        _ destination: Destination,
        with replacement: Destination,
        on pathID: PathID?,
        search: RouterPathSearchDirection
    ) -> Bool
    {
        p_performNavigation(
            .replace(destination, with: replacement, search: search),
            on: pathID
        ) { path, _ in
            Self.replace(
                &path,
                destination: destination,
                with: replacement,
                search: search
            )
        }.succeeded
    }

    @discardableResult
    func replace(
        flat: Destination.Flat,
        with replacement: Destination,
        on pathID: PathID?,
        search: RouterPathSearchDirection
    ) -> Bool
    {
        p_performNavigation(
            .replaceFlat(flat, with: replacement, search: search),
            on: pathID
        ) { path, _ in
            Self.replace(
                &path,
                flat: flat,
                with: replacement,
                search: search
            )
        }.succeeded
    }

    @discardableResult
    func push(_ destination: Destination) -> PathID?
    {
        push(destination, to: Optional<PathID>.none, options: [])
    }

    @discardableResult
    func push(
        _ destination: Destination,
        options: RouterPushOptions
    ) -> PathID?
    {
        push(destination, to: Optional<PathID>.none, options: options)
    }

    @discardableResult
    func push(_ destination: Destination, to pathID: PathID) -> PathID?
    {
        push(destination, to: Optional(pathID), options: [])
    }

    @discardableResult
    func popAll() -> Bool
    {
        popAll(Optional<PathID>.none)
    }

    @discardableResult
    func pop(amount: Int = 1) -> Bool
    {
        pop(Optional<PathID>.none, amount: amount)
    }

    @discardableResult
    func pop(_ pathID: PathID, amount: Int = 1) -> Bool
    {
        pop(Optional(pathID), amount: amount)
    }

    @discardableResult
    func pop(to destination: Destination) -> Bool
    {
        pop(Optional<PathID>.none, to: destination)
    }

    @discardableResult
    func pop(_ pathID: PathID, to destination: Destination) -> Bool
    {
        pop(Optional(pathID), to: destination)
    }

    @discardableResult
    func pop(toFlat destination: Destination.Flat) -> Bool
    {
        pop(Optional<PathID>.none, toFlat: destination)
    }

    @discardableResult
    func pop(_ pathID: PathID, toFlat destination: Destination.Flat) -> Bool
    {
        pop(Optional(pathID), toFlat: destination)
    }

    @discardableResult
    func replace(
        _ destination: Destination,
        with replacement: Destination,
        search: RouterPathSearchDirection = .last
    ) -> Bool
    {
        replace(
            destination,
            with: replacement,
            on: Optional<PathID>.none,
            search: search
        )
    }

    @discardableResult
    func replace(
        _ destination: Destination,
        with replacement: Destination,
        on pathID: PathID,
        search: RouterPathSearchDirection = .last
    ) -> Bool
    {
        replace(
            destination,
            with: replacement,
            on: Optional(pathID),
            search: search
        )
    }

    @discardableResult
    func replace(
        flat: Destination.Flat,
        with replacement: Destination,
        search: RouterPathSearchDirection = .last
    ) -> Bool
    {
        replace(
            flat: flat,
            with: replacement,
            on: Optional<PathID>.none,
            search: search
        )
    }

    @discardableResult
    func replace(
        flat: Destination.Flat,
        with replacement: Destination,
        on pathID: PathID,
        search: RouterPathSearchDirection = .last
    ) -> Bool
    {
        replace(
            flat: flat,
            with: replacement,
            on: Optional(pathID),
            search: search
        )
    }
}

internal extension RouterProtocol
{
    func p_performNavigation(
        _ operation: RouterNavigationOperation<Destination>,
        on requestedPathID: PathID?,
        mutation: (inout [Destination], PathID) -> Bool
    ) -> (succeeded: Bool, pathID: PathID?)
    {
        let resolvedPathID = resolvePathID(requestedPathID)

        guard shouldPerformNavigation(operation, on: resolvedPathID),
              let resolvedPathID else
        {
            routerDidPerform(RouterNavigationEvent(
                operation: operation,
                requestedPathID: requestedPathID,
                resolvedPathID: resolvedPathID,
                pathCountBefore: nil,
                pathCountAfter: nil,
                succeeded: false
            ))
            return (false, resolvedPathID)
        }

        var operationSucceeded = false
        var pathCountBefore: Int?
        var pathCountAfter: Int?
        let foundPath = withPath(resolvedPathID) { path in
            pathCountBefore = path.count
            operationSucceeded = mutation(&path, resolvedPathID)
            pathCountAfter = path.count
        }
        let succeeded = foundPath && operationSucceeded

        routerDidPerform(RouterNavigationEvent(
            operation: operation,
            requestedPathID: requestedPathID,
            resolvedPathID: resolvedPathID,
            pathCountBefore: pathCountBefore,
            pathCountAfter: pathCountAfter,
            succeeded: succeeded
        ))

        return (succeeded, resolvedPathID)
    }
}
