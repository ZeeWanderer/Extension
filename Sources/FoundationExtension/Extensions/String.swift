//
//  String.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation

public extension String
{
    static var empty: String { "" }
    
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, visionOS 1.0, *)
    var localizedResource: LocalizedStringResource
    {
        LocalizedStringResource(stringLiteral: self)
    }
    
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
