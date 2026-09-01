//
//  SparseCacheError.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

/// Configuration and operation failures reported by ``SparseCache``.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public enum SparseCacheError: Error, Sendable
{
    case invalidConfiguration(String)
    case sparseFilesUnsupported(URL)
    case invalidCapacity
    case invalidRange
    case entryNotPrepared
    case entryExpired
    case invalidEntry
    case incompleteRead(expectedByteCount: Int, actualByteCount: Int)
    case incompleteWrite(expectedByteCount: Int, actualByteCount: Int)
}
