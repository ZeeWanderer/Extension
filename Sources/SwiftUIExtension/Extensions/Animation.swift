//
//  Animation.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//


import SwiftUI

public extension Animation
{
    @inlinable
    func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation
    {
        if expression
        {
            return self.repeatForever(autoreverses: autoreverses)
        }
        else
        {
            return self
        }
    }
}
