//
//  Decimal.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//

import Foundation

public extension Decimal
{
    @_transparent
    var isNotZero: Bool { !isZero }
}
