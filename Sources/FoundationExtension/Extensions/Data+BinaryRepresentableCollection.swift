//
//  Data+BinaryRepresentableCollection.swift
//  Extension
//
//  Created by zeewanderer on 20.11.2026.
//

import Foundation

public extension Data
{
    /// Loads a collection from its consecutive native elements.
    @inlinable
    func load<T: BinaryRepresentableCollection>(as type: T.Type) -> T
    {
        guard let value = saferLoad(as: type) else {
            preconditionFailure("Invalid binary collection representation for \(type)")
        }
        return value
    }

    /// Returns nil when the payload ends partway through an element.
    func saferLoad<T: BinaryRepresentableCollection>(as type: T.Type) -> T?
    { P_BinaryCollectionFormat.decode(type, from: self) }
}
