//
//  P_CacheReadOutcome.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal enum P_CacheReadOutcome<Value: Sendable>: @unchecked Sendable
{
    case value(CacheStoreID, CacheEntry<Value>?)
    case failure(CacheStoreFailure)

    @inlinable
    internal var storeID: CacheStoreID
    {
        switch self
        {
        case let .value(storeID, _):
            storeID
        case let .failure(failure):
            failure.storeID
        }
    }
}
