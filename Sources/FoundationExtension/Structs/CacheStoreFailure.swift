//
//  CacheStoreFailure.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// A failure attributed to one configured cache store.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheStoreFailure: Error, @unchecked Sendable
{
    public let storeID: CacheStoreID
    public let operation: CacheOperation
    public let underlyingError: any Error

    @inlinable
    public init(
        storeID: CacheStoreID,
        operation: CacheOperation,
        underlyingError: any Error
    )
    {
        self.storeID = storeID
        self.operation = operation
        self.underlyingError = underlyingError
    }
}
