//
//  JSONCodingError.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

/// Errors produced by ``JSONCoding`` resource conveniences.
public enum JSONCodingError: Error, Equatable, Sendable, LocalizedError
{
    /// The requested resource does not exist in the supplied bundle.
    case resourceNotFound(
        name: String,
        fileExtension: String?,
        subdirectory: String?
    )

    public var errorDescription: String?
    {
        switch self
        {
        case .resourceNotFound(let name, let fileExtension, let subdirectory):
            let filename = fileExtension.map { "\(name).\($0)" } ?? name
            let location = subdirectory.map { " in subdirectory \($0)" } ?? ""
            return "Could not find resource \(filename)\(location)"
        }
    }
}
