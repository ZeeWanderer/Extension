//
//  Core.swift
//  Extension
//
//  Created by zeewanderer on 17.04.2025.
//

import Foundation

internal extension String
{
    @usableFromInline
    func indent(by spaces: Int) -> String {
        let pad = String(repeating: " ", count: spaces)
        return self.split(separator: "\n").map { pad + $0 }.joined(separator: "\n")
    }
}

