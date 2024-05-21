//
//  String.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

public extension String
{
    @inlinable
    func condenseWhitespace() -> String
    {
        let components = self.components(separatedBy: .whitespaces)
        return components.filter
        { substr in
            !substr.isEmpty
        }.joined(separator: " ")
    }
}
