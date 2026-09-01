//
//  P_CacheDiskEntryRecord.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal struct P_CacheDiskEntryRecord: Sendable
{
    @usableFromInline internal let primaryURL: URL
    @usableFromInline internal let relatedURLs: [URL]
    @usableFromInline internal let capacity: UInt64
    @usableFromInline internal var lastAccessDate: Date
    @usableFromInline internal let expirationDate: Date?
    @usableFromInline internal let isInvalid: Bool
    @usableFromInline internal let isSparse: Bool

    @inlinable
    internal init(
        primaryURL: URL,
        relatedURLs: [URL],
        capacity: UInt64,
        lastAccessDate: Date,
        expirationDate: Date?,
        isInvalid: Bool,
        isSparse: Bool
    )
    {
        self.primaryURL = primaryURL
        self.relatedURLs = relatedURLs
        self.capacity = capacity
        self.lastAccessDate = lastAccessDate
        self.expirationDate = expirationDate
        self.isInvalid = isInvalid
        self.isSparse = isSparse
    }
}
