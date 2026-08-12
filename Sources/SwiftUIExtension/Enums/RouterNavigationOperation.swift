//
//  RouterNavigationOperation.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// A navigation mutation requested from a router.
public enum RouterNavigationOperation<Destination>
where Destination: RouterDestination
{
    case push(Destination, options: RouterPushOptions)
    case pop(amount: Int)
    case popTo(Destination)
    case popToFlat(Destination.Flat)
    case popAll
    case replace(
        Destination,
        with: Destination,
        search: RouterPathSearchDirection
    )
    case replaceFlat(
        Destination.Flat,
        with: Destination,
        search: RouterPathSearchDirection
    )
}
