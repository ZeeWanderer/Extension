//
//  Collection.swift
//
//
//  Created by zee wanderer on 29.08.2024.
//

import Foundation

public extension Collection
{
    @inlinable
    @inline(__always)
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
}
