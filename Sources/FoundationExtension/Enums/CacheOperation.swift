//
//  CacheOperation.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// A store operation performed by a ``Cache``.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public enum CacheOperation: Hashable, Sendable
{
    case retrieve
    case store
    case remove
    case removeAll
    case maintenance
    case promote
    case rollback
}
