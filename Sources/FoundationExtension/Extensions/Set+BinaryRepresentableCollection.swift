//
//  Set+BinaryRepresentableCollection.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import Foundation

extension Set: BinaryRepresentable where Element: BinaryRepresentable  { }
extension Set: BinaryRepresentableCollection where Element: BinaryRepresentable { }

public extension Set where Element: BinaryRepresentable
{
    /// The set's compact binary payload in its current iteration order.
    ///
    /// - Warning: Set iteration order is unspecified. Equal sets can produce
    ///   different payload bytes across processes or construction histories.
    ///   Decoding preserves membership; use ``stableData(sortedBy:)`` when the
    ///   payload itself must be reproducible.
    var data: Data
    {
        Array(self).data
    }

    /// Encodes the set in a caller-defined stable order.
    ///
    /// Equal sets produce equal payloads when `areInIncreasingOrder` provides
    /// the same strict total order and each element has a stable representation.
    func stableData(
        sortedBy areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> Data
    {
        try sorted(by: areInIncreasingOrder).data
    }
}
