//
//  P_CacheMutationOutcome.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal enum P_CacheMutationOutcome: @unchecked Sendable
{
    case success(CacheStoreID)
    case failure(CacheStoreFailure)

    @inlinable
    internal var storeID: CacheStoreID
    {
        switch self
        {
        case let .success(storeID):
            storeID
        case let .failure(failure):
            failure.storeID
        }
    }
}
