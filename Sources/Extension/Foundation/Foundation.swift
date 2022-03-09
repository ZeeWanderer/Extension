//
//  Basic.swift
//  
//
//  Created by Maksym Kulyk on 09.03.2022.
//

import Foundation

public extension String
{
    @inlinable func condenseWhitespace() -> String
    {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter
        {
            !$0.isEmpty
        }.joined(separator: " ")
    }
}
