//
//  CacheMaintenanceReport.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

/// Ordered results from a ``Cache`` maintenance operation.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheMaintenanceReport: Sendable
{
    /// The result attributed to one configured store.
    public struct StoreResult: Hashable, Sendable
    {
        public let storeID: CacheStoreID
        public let result: CacheStoreMaintenanceResult

        @inlinable
        public init(
            storeID: CacheStoreID,
            result: CacheStoreMaintenanceResult
        )
        {
            self.storeID = storeID
            self.result = result
        }
    }

    /// Results in the selected stores' deterministic order.
    public let storeResults: [StoreResult]
    /// Tolerated failures in the selected stores' deterministic order.
    public let failures: [CacheStoreFailure]

    @inlinable
    public init(
        storeResults: [StoreResult],
        failures: [CacheStoreFailure] = []
    )
    {
        self.storeResults = storeResults
        self.failures = failures
    }

    /// Returns the result for a selected store.
    @inlinable
    public subscript(storeID storeID: CacheStoreID) -> CacheStoreMaintenanceResult?
    {
        storeResults.first { $0.storeID == storeID }?.result
    }
}
