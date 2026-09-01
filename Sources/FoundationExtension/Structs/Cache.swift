//
//  Cache.swift
//  Extension
//
//  Created by zeewanderer on 19.04.2025.
//

import Foundation

/// A configurable dispatcher over one or more cache stores.
///
/// Isolation is keyed across the complete store hierarchy. Read-only
/// operations for one key may overlap, while writes and reads that can promote
/// a value are barriers for that key. Operations for different keys remain
/// independent. `removeAll()` is a cache-wide barrier. Maintenance is an
/// optional store-local eviction operation and relies on each store's own
/// concurrency boundary.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public final class Cache<
    Key: Hashable & Sendable,
    Value: Sendable
>: @unchecked Sendable
{
    /// Selects a route from the key being accessed.
    public typealias RouteProvider = @Sendable (Key) -> CacheRoute

    @usableFromInline
    internal struct P_CompiledRoute: Sendable
    {
        @usableFromInline internal let readStages: [[CacheStore<Key, Value>]]
        @usableFromInline internal let writeStores: [CacheStore<Key, Value>]
        @usableFromInline internal let promotions: [CacheStoreID: [CacheStore<Key, Value>]]
        @usableFromInline internal let readFailurePolicy: CacheFailurePolicy
        @usableFromInline internal let promotionFailurePolicy: CacheFailurePolicy
        @usableFromInline internal let mayPromote: Bool
        @usableFromInline internal let writeStoreIDs: Set<CacheStoreID>

        @inlinable
        internal init(
            readStages: [[CacheStore<Key, Value>]],
            writeStores: [CacheStore<Key, Value>],
            promotions: [CacheStoreID: [CacheStore<Key, Value>]],
            readFailurePolicy: CacheFailurePolicy,
            promotionFailurePolicy: CacheFailurePolicy,
            mayPromote: Bool,
            writeStoreIDs: Set<CacheStoreID>
        )
        {
            self.readStages = readStages
            self.writeStores = writeStores
            self.promotions = promotions
            self.readFailurePolicy = readFailurePolicy
            self.promotionFailurePolicy = promotionFailurePolicy
            self.mayPromote = mayPromote
            self.writeStoreIDs = writeStoreIDs
        }
    }

    @usableFromInline
    internal enum P_Mutation: Sendable
    {
        case store(CacheStore<Key, Value>, CacheEntry<Value>, CacheOperation)
        case remove(CacheStore<Key, Value>, CacheOperation)

        @inlinable
        internal var store: CacheStore<Key, Value>
        {
            switch self
            {
            case let .store(store, _, _), let .remove(store, _):
                store
            }
        }

        @inlinable
        internal var operation: CacheOperation
        {
            switch self
            {
            case let .store(_, _, operation), let .remove(_, operation):
                operation
            }
        }
    }

    @usableFromInline
    internal enum P_MaintenanceOutcome: @unchecked Sendable
    {
        case result(CacheMaintenanceReport.StoreResult)
        case failure(CacheStoreFailure)

        @inlinable
        internal var storeID: CacheStoreID
        {
            switch self
            {
            case let .result(result):
                result.storeID
            case let .failure(failure):
                failure.storeID
            }
        }
    }

    @usableFromInline internal let p_stores: [CacheStore<Key, Value>]
    @usableFromInline internal let p_storesByID: [CacheStoreID: CacheStore<Key, Value>]
    @usableFromInline internal let p_routeProvider: RouteProvider?
    @usableFromInline internal let p_defaultRoute: P_CompiledRoute?
    @usableFromInline internal let p_ownershipToken = UUID()
    @usableFromInline internal let p_globalGate = P_CacheReadWriteGate()
    @usableFromInline internal let p_keyGates: P_CacheKeyGateRegistry<Key>

    /// The configured store identifiers in initializer order.
    @inlinable
    public var storeIDs: [CacheStoreID]
    {
        p_stores.map(\.id)
    }

    /// Creates a dispatcher from opaque stores and a fixed route.
    ///
    /// A store can belong to only one live dispatcher. The dispatcher does not
    /// expose store mutation, keeping all changes inside its isolation rules.
    @inlinable
    public convenience init(
        stores: [CacheStore<Key, Value>],
        retainedKeyGateLimit: Int = 1024,
        route: CacheRoute? = nil
    ) throws
    {
        try self.init(
            stores: stores,
            retainedKeyGateLimit: retainedKeyGateLimit,
            fixedRoute: route,
            routeProvider: nil
        )
    }

    /// Creates a dispatcher with a route selected independently for every key.
    @inlinable
    public convenience init(
        stores: [CacheStore<Key, Value>],
        retainedKeyGateLimit: Int = 1024,
        routeProvider: @escaping RouteProvider
    ) throws
    {
        try self.init(
            stores: stores,
            retainedKeyGateLimit: retainedKeyGateLimit,
            fixedRoute: nil,
            routeProvider: routeProvider
        )
    }

    @inlinable
    internal init(
        stores: [CacheStore<Key, Value>],
        retainedKeyGateLimit: Int,
        fixedRoute: CacheRoute?,
        routeProvider: RouteProvider?
    ) throws
    {
        guard !stores.isEmpty else { throw CacheError.emptyStoreList }

        var storesByID: [CacheStoreID: CacheStore<Key, Value>] = [:]
        for store in stores
        {
            guard storesByID[store.id] == nil else
            {
                throw CacheError.duplicateStoreID(store.id)
            }
            storesByID[store.id] = store
        }

        let compiledDefaultRoute = try routeProvider == nil
            ? Self.p_compile(
                fixedRoute ?? CacheRoute.hierarchy(stores.map(\.id)),
                storesByID: storesByID
            )
            : nil

        var claimedStores: [CacheStore<Key, Value>] = []
        for store in stores
        {
            guard store.p_ownership.claim(p_ownershipToken) else
            {
                for claimedStore in claimedStores
                {
                    claimedStore.p_ownership.release(p_ownershipToken)
                }
                throw CacheError.storeAlreadyAttached(store.id)
            }
            claimedStores.append(store)
        }

        self.p_stores = stores
        self.p_storesByID = storesByID
        self.p_keyGates = P_CacheKeyGateRegistry(
            maximumRetainedGateCount: retainedKeyGateLimit
        )
        self.p_routeProvider = routeProvider
        self.p_defaultRoute = compiledDefaultRoute
    }

    /// Creates a cache with one configurable in-memory store.
    @inlinable
    public convenience init(
        memoryConfiguration: MemoryCacheConfiguration = .init(),
        cost: @escaping @Sendable (Value) -> Int = { _ in 0 }
    )
    {
        try! self.init(
            stores: [
                .memory(configuration: memoryConfiguration, cost: cost),
            ],
            retainedKeyGateLimit: 1024,
            fixedRoute: nil,
            routeProvider: nil
        )
    }

    deinit
    {
        for store in p_stores
        {
            store.p_ownership.release(p_ownershipToken)
        }
    }

    // MARK: - Synchronous API

    /// Returns a value and the store that supplied it, blocking the caller.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func hit(
        forKey key: Key,
        route: CacheRoute? = nil
    ) throws -> CacheHit<Value>?
    {
        let route = try p_compiledRoute(for: key, override: route)
        let access: P_CacheReadWriteGate.Access = route.mayPromote
            ? .write
            : .read
        return try p_withSynchronousKeyAccess(key, access: access) {
            try p_retrieveSynchronously(for: key, route: route)
        }
    }

    /// Returns the cached value, blocking the caller.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func value(
        forKey key: Key,
        route: CacheRoute? = nil
    ) throws -> Value?
    {
        try hit(forKey: key, route: route)?.value
    }

    /// Returns a hit from exactly one registered store without promotion.
    ///
    /// This is a read-only view through the dispatcher's key isolation. It does
    /// not expose or transfer ownership of the underlying store.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func hit(
        forKey key: Key,
        from storeID: CacheStoreID
    ) throws -> CacheHit<Value>?
    {
        let route = try Self.p_compile(
            CacheRoute(
                readStages: [[storeID]],
                readFailurePolicy: .fail
            ),
            storesByID: p_storesByID
        )
        return try p_withSynchronousKeyAccess(key, access: .read) {
            try p_retrieveSynchronously(for: key, route: route)
        }
    }

    /// Returns a value from exactly one registered store without promotion.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func value(
        forKey key: Key,
        from storeID: CacheStoreID
    ) throws -> Value?
    {
        try hit(forKey: key, from: storeID)?.value
    }

    /// Inserts a value through the selected route, blocking the caller.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func insert(
        _ value: Value,
        forKey key: Key,
        expirationDate: Date? = nil,
        cost: Int = 0,
        route: CacheRoute? = nil
    ) throws
    {
        try insert(
            CacheEntry(
                value,
                expirationDate: expirationDate,
                cost: cost
            ),
            forKey: key,
            route: route
        )
    }

    /// Inserts an entry through the selected route, blocking the caller.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func insert(
        _ entry: CacheEntry<Value>,
        forKey key: Key,
        route: CacheRoute? = nil
    ) throws
    {
        let route = try p_compiledRoute(for: key, override: route)
        guard !route.writeStores.isEmpty else { throw CacheError.noWriteStores }
        try p_withSynchronousKeyAccess(key, access: .write) {
            try p_storeSynchronously(entry, for: key, route: route)
        }
    }

    /// Inserts a value into a requested store while preserving resident copies.
    ///
    /// The requested store always receives the value. Every other store that
    /// currently contains an unexpired copy is updated in the same per-key
    /// transaction, while stores where the key is absent remain absent. The
    /// operation first reads every store and fails before mutation if residency
    /// cannot be determined. Use a ``CacheRoute`` write when the intended
    /// behavior is instead to invalidate every store outside a fixed target set.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func insert(
        _ value: Value,
        forKey key: Key,
        expirationDate: Date? = nil,
        cost: Int = 0,
        targeting storeID: CacheStoreID
    ) throws
    {
        try insert(
            CacheEntry(
                value,
                expirationDate: expirationDate,
                cost: cost
            ),
            forKey: key,
            targeting: storeID
        )
    }

    /// Inserts an entry into a requested store while preserving resident copies.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func insert(
        _ entry: CacheEntry<Value>,
        forKey key: Key,
        targeting storeID: CacheStoreID
    ) throws
    {
        guard p_storesByID[storeID] != nil else
        {
            throw CacheError.unknownStoreID(storeID)
        }
        try p_withSynchronousKeyAccess(key, access: .write) {
            try p_storeUpdatingResidentCopiesSynchronously(
                entry,
                for: key,
                targeting: storeID
            )
        }
    }

    /// Removes a key from every store, blocking the caller.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func removeValue(forKey key: Key) throws
    {
        try p_withSynchronousKeyAccess(key, access: .write) {
            let mutations = p_stores.map {
                P_Mutation.remove($0, .remove)
            }
            let failures = p_performSynchronously(mutations, for: key)
            if !failures.isEmpty
            {
                throw CacheError.storeFailures(failures)
            }
        }
    }

    /// Removes every entry from every store, blocking the caller.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func removeAll() throws
    {
        p_globalGate.acquire(.write)
        defer { p_globalGate.release(.write) }

        let failures = p_performRemoveAllSynchronously()
        if !failures.isEmpty
        {
            throw CacheError.storeFailures(failures)
        }
    }

    /// Performs maintenance on selected stores, blocking the caller.
    ///
    /// Stores are visited in deterministic selection order. A store without a
    /// maintenance implementation reports `unsupported`. A store that only
    /// provides asynchronous maintenance reports
    /// ``CacheError/synchronousAccessUnavailable(_:)``.
    @available(*, noasync, message: "Use the async cache API from an async context")
    @inlinable
    public func performMaintenance(
        storeIDs: [CacheStoreID]? = nil,
        mode: CacheMaintenanceMode = .forced,
        failurePolicy: CacheFailurePolicy = .fail
    ) throws -> CacheMaintenanceReport
    {
        let stores = try p_storesForMaintenance(storeIDs)
        var results: [CacheMaintenanceReport.StoreResult] = []
        var failures: [CacheStoreFailure] = []
        results.reserveCapacity(stores.count)

        for store in stores
        {
            if let maintenance = store.p_synchronous?.p_maintenance
            {
                do
                {
                    results.append(.init(
                        storeID: store.id,
                        result: try maintenance(mode)
                    ))
                }
                catch
                {
                    failures.append(CacheStoreFailure(
                        storeID: store.id,
                        operation: .maintenance,
                        underlyingError: error
                    ))
                }
            }
            else if store.p_maintenance != nil
            {
                failures.append(CacheStoreFailure(
                    storeID: store.id,
                    operation: .maintenance,
                    underlyingError: CacheError.synchronousAccessUnavailable(
                        store.id
                    )
                ))
            }
            else
            {
                results.append(.init(
                    storeID: store.id,
                    result: .unsupported
                ))
            }
        }

        if failurePolicy == .fail, !failures.isEmpty
        {
            throw CacheError.storeFailures(failures)
        }
        return CacheMaintenanceReport(
            storeResults: results,
            failures: failures
        )
    }

    // MARK: - Async API

    /// Returns a value and the store that supplied it without blocking the caller.
    @inlinable
    public func hit(
        forKey key: Key,
        route: CacheRoute? = nil
    ) async throws -> CacheHit<Value>?
    {
        let route = try p_compiledRoute(for: key, override: route)
        let access: P_CacheReadWriteGate.Access = route.mayPromote
            ? .write
            : .read
        return try await p_withAsyncKeyAccess(key, access: access) {
            try await self.p_retrieve(for: key, route: route)
        }
    }

    /// Returns the cached value without blocking the caller.
    @inlinable
    public func value(
        forKey key: Key,
        route: CacheRoute? = nil
    ) async throws -> Value?
    {
        try await hit(forKey: key, route: route)?.value
    }

    /// Returns a hit from exactly one registered store without promotion.
    @inlinable
    public func hit(
        forKey key: Key,
        from storeID: CacheStoreID
    ) async throws -> CacheHit<Value>?
    {
        let route = try Self.p_compile(
            CacheRoute(
                readStages: [[storeID]],
                readFailurePolicy: .fail
            ),
            storesByID: p_storesByID
        )
        return try await p_withAsyncKeyAccess(key, access: .read) {
            try await self.p_retrieve(for: key, route: route)
        }
    }

    /// Returns a value from exactly one registered store without promotion.
    @inlinable
    public func value(
        forKey key: Key,
        from storeID: CacheStoreID
    ) async throws -> Value?
    {
        try await hit(forKey: key, from: storeID)?.value
    }

    /// Inserts a value without blocking the caller.
    @inlinable
    public func insert(
        _ value: Value,
        forKey key: Key,
        expirationDate: Date? = nil,
        cost: Int = 0,
        route: CacheRoute? = nil
    ) async throws
    {
        try await insert(
            CacheEntry(
                value,
                expirationDate: expirationDate,
                cost: cost
            ),
            forKey: key,
            route: route
        )
    }

    /// Inserts an entry without blocking the caller.
    @inlinable
    public func insert(
        _ entry: CacheEntry<Value>,
        forKey key: Key,
        route: CacheRoute? = nil
    ) async throws
    {
        let route = try p_compiledRoute(for: key, override: route)
        guard !route.writeStores.isEmpty else { throw CacheError.noWriteStores }
        try await p_withAsyncKeyAccess(key, access: .write) {
            try await self.p_store(entry, for: key, route: route)
        }
    }

    /// Inserts a value into a requested store while preserving resident copies.
    ///
    /// The requested store always receives the value. Every other store that
    /// currently contains an unexpired copy is updated in the same per-key
    /// transaction, while stores where the key is absent remain absent. The
    /// operation first reads every store and fails before mutation if residency
    /// cannot be determined. Use a ``CacheRoute`` write when the intended
    /// behavior is instead to invalidate every store outside a fixed target set.
    @inlinable
    public func insert(
        _ value: Value,
        forKey key: Key,
        expirationDate: Date? = nil,
        cost: Int = 0,
        targeting storeID: CacheStoreID
    ) async throws
    {
        try await insert(
            CacheEntry(
                value,
                expirationDate: expirationDate,
                cost: cost
            ),
            forKey: key,
            targeting: storeID
        )
    }

    /// Inserts an entry into a requested store while preserving resident copies.
    @inlinable
    public func insert(
        _ entry: CacheEntry<Value>,
        forKey key: Key,
        targeting storeID: CacheStoreID
    ) async throws
    {
        guard p_storesByID[storeID] != nil else
        {
            throw CacheError.unknownStoreID(storeID)
        }
        try await p_withAsyncKeyAccess(key, access: .write) {
            try await self.p_storeUpdatingResidentCopies(
                entry,
                for: key,
                targeting: storeID
            )
        }
    }

    /// Removes a key from every store without blocking the caller.
    @inlinable
    public func removeValue(forKey key: Key) async throws
    {
        try await p_withAsyncKeyAccess(key, access: .write) {
            let mutations = self.p_stores.map {
                P_Mutation.remove($0, .remove)
            }
            let failures = await self.p_perform(mutations, for: key)
            if !failures.isEmpty
            {
                throw CacheError.storeFailures(failures)
            }
        }
    }

    /// Removes every entry behind a cache-wide asynchronous barrier.
    @inlinable
    public func removeAll() async throws
    {
        try Task.checkCancellation()
        await p_globalGate.acquire(.write)
        if Task.isCancelled
        {
            p_globalGate.release(.write)
            throw CancellationError()
        }
        defer { p_globalGate.release(.write) }

        let failures: [CacheStoreFailure]
        if p_stores.count == 1, let store = p_stores.first
        {
            do
            {
                try await store.p_removeAll()
                failures = []
            }
            catch
            {
                failures = [CacheStoreFailure(
                    storeID: store.id,
                    operation: .removeAll,
                    underlyingError: error
                )]
            }
        }
        else
        {
            failures = await withTaskGroup(
                of: P_CacheMutationOutcome.self,
                returning: [CacheStoreFailure].self
            ) { group in
                for store in p_stores
                {
                    group.addTask { [store] in
                        do
                        {
                            try await store.p_removeAll()
                            return .success(store.id)
                        }
                        catch
                        {
                            return .failure(CacheStoreFailure(
                                storeID: store.id,
                                operation: .removeAll,
                                underlyingError: error
                            ))
                        }
                    }
                }

                var outcomes: [CacheStoreID: P_CacheMutationOutcome] = [:]
                for await outcome in group
                {
                    outcomes[outcome.storeID] = outcome
                }
                return p_stores.compactMap { store in
                    guard case let .failure(failure) = outcomes[store.id] else { return nil }
                    return failure
                }
            }
        }
        if !failures.isEmpty
        {
            throw CacheError.storeFailures(failures)
        }
    }

    /// Performs maintenance on selected stores without blocking the caller.
    ///
    /// Selected stores run concurrently. Store-level maintenance may overlap
    /// ordinary cache operations when that store can do so safely; each store
    /// is responsible for protecting its own eviction boundary. Results and
    /// tolerated failures retain deterministic selection order.
    @inlinable
    public func performMaintenance(
        storeIDs: [CacheStoreID]? = nil,
        mode: CacheMaintenanceMode = .forced,
        failurePolicy: CacheFailurePolicy = .fail
    ) async throws -> CacheMaintenanceReport
    {
        try Task.checkCancellation()
        let stores = try p_storesForMaintenance(storeIDs)
        let outcomes = await withTaskGroup(
            of: P_MaintenanceOutcome.self,
            returning: [CacheStoreID: P_MaintenanceOutcome].self
        ) { group in
            var immediate: [CacheStoreID: P_MaintenanceOutcome] = [:]
            for store in stores
            {
                guard let maintenance = store.p_maintenance else
                {
                    immediate[store.id] = .result(.init(
                        storeID: store.id,
                        result: .unsupported
                    ))
                    continue
                }
                group.addTask { [store, maintenance, mode] in
                    do
                    {
                        return .result(.init(
                            storeID: store.id,
                            result: try await maintenance(mode)
                        ))
                    }
                    catch
                    {
                        return .failure(CacheStoreFailure(
                            storeID: store.id,
                            operation: .maintenance,
                            underlyingError: error
                        ))
                    }
                }
            }

            for await outcome in group
            {
                immediate[outcome.storeID] = outcome
            }
            return immediate
        }
        try Task.checkCancellation()

        var results: [CacheMaintenanceReport.StoreResult] = []
        var failures: [CacheStoreFailure] = []
        results.reserveCapacity(stores.count)
        for store in stores
        {
            switch outcomes[store.id]
            {
            case let .result(result):
                results.append(result)
            case let .failure(failure):
                failures.append(failure)
            case nil:
                assertionFailure("Missing cache maintenance outcome")
            }
        }
        if failurePolicy == .fail, !failures.isEmpty
        {
            throw CacheError.storeFailures(failures)
        }
        return CacheMaintenanceReport(
            storeResults: results,
            failures: failures
        )
    }

    /// Starts unstructured maintenance work that can be awaited later.
    ///
    /// The job runs at utility priority and does not inherit a caller's actor.
    /// Cancelling the returned task cancels maintenance at its next cooperative
    /// cancellation point.
    @inlinable
    public func startMaintenance(
        storeIDs: [CacheStoreID]? = nil,
        mode: CacheMaintenanceMode = .forced,
        failurePolicy: CacheFailurePolicy = .fail
    ) -> Task<CacheMaintenanceReport, any Error>
    {
        Task.detached(priority: .utility) { [self] in
            try await performMaintenance(
                storeIDs: storeIDs,
                mode: mode,
                failurePolicy: failurePolicy
            )
        }
    }

    // MARK: - Routing

    @inlinable
    internal func p_compiledRoute(
        for key: Key,
        override: CacheRoute?
    ) throws -> P_CompiledRoute
    {
        if override == nil, let p_defaultRoute
        {
            return p_defaultRoute
        }
        let route = override ?? p_routeProvider!(key)
        return try Self.p_compile(route, storesByID: p_storesByID)
    }

    @inlinable
    internal func p_storesForMaintenance(
        _ storeIDs: [CacheStoreID]?
    ) throws -> [CacheStore<Key, Value>]
    {
        guard let storeIDs else { return p_stores }
        var seen: Set<CacheStoreID> = []
        return try storeIDs.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            guard let store = p_storesByID[id] else
            {
                throw CacheError.unknownStoreID(id)
            }
            return store
        }
    }

    @inlinable
    internal static func p_compile(
        _ route: CacheRoute,
        storesByID: [CacheStoreID: CacheStore<Key, Value>]
    ) throws -> P_CompiledRoute
    {
        func stores(for ids: [CacheStoreID]) throws -> [CacheStore<Key, Value>]
        {
            var seen: Set<CacheStoreID> = []
            return try ids.compactMap { id in
                guard seen.insert(id).inserted else { return nil }
                guard let store = storesByID[id] else
                {
                    throw CacheError.unknownStoreID(id)
                }
                return store
            }
        }

        let readStages = try route.readStages.map(stores(for:))
        let writeStores = try stores(for: route.writeStores)
        var promotions: [CacheStoreID: [CacheStore<Key, Value>]] = [:]
        for (source, targets) in route.promotions
        {
            guard storesByID[source] != nil else
            {
                throw CacheError.unknownStoreID(source)
            }
            promotions[source] = try stores(for: targets).filter {
                $0.id != source
            }
        }
        return P_CompiledRoute(
            readStages: readStages,
            writeStores: writeStores,
            promotions: promotions,
            readFailurePolicy: route.readFailurePolicy,
            promotionFailurePolicy: route.promotionFailurePolicy,
            mayPromote: promotions.values.contains { !$0.isEmpty },
            writeStoreIDs: Set(writeStores.map(\.id))
        )
    }

    // MARK: - Async internals

    @inlinable
    internal func p_retrieve(
        for key: Key,
        route: P_CompiledRoute
    ) async throws -> CacheHit<Value>?
    {
        for stage in route.readStages
        {
            try Task.checkCancellation()
            let outcomes = await p_read(stage, for: key)
            try Task.checkCancellation()
            let failures = outcomes.compactMap { outcome -> CacheStoreFailure? in
                guard case let .failure(failure) = outcome else { return nil }
                return failure
            }
            if route.readFailurePolicy == .fail, !failures.isEmpty
            {
                throw CacheError.storeFailures(failures)
            }

            for outcome in outcomes
            {
                guard case let .value(storeID, entry?) = outcome,
                      !entry.isExpired() else { continue }

                let hit = CacheHit(entry: entry, storeID: storeID)
                if let targets = route.promotions[storeID], !targets.isEmpty
                {
                    let mutations = targets.map {
                        P_Mutation.store($0, entry, .promote)
                    }
                    let promotionFailures = await p_perform(mutations, for: key)
                    if !promotionFailures.isEmpty
                    {
                        let rollback = targets.map {
                            P_Mutation.remove($0, .rollback)
                        }
                        let rollbackFailures = await p_perform(rollback, for: key)
                        if route.promotionFailurePolicy == .fail
                        {
                            throw CacheError.storeFailures(
                                promotionFailures + rollbackFailures
                            )
                        }
                    }
                }
                return hit
            }
        }
        return nil
    }

    @inlinable
    internal func p_read(
        _ stores: [CacheStore<Key, Value>],
        for key: Key
    ) async -> [P_CacheReadOutcome<Value>]
    {
        guard stores.count > 1 else
        {
            guard let store = stores.first else { return [] }
            do
            {
                return [.value(store.id, try await store.p_retrieve(key))]
            }
            catch
            {
                return [.failure(CacheStoreFailure(
                    storeID: store.id,
                    operation: .retrieve,
                    underlyingError: error
                ))]
            }
        }

        return await withTaskGroup(
            of: P_CacheReadOutcome<Value>.self,
            returning: [P_CacheReadOutcome<Value>].self
        ) { group in
            for store in stores
            {
                group.addTask { [key, store] in
                    do
                    {
                        return .value(
                            store.id,
                            try await store.p_retrieve(key)
                        )
                    }
                    catch
                    {
                        return .failure(CacheStoreFailure(
                            storeID: store.id,
                            operation: .retrieve,
                            underlyingError: error
                        ))
                    }
                }
            }

            var ordered: [CacheStoreID: P_CacheReadOutcome<Value>] = [:]
            for await outcome in group
            {
                ordered[outcome.storeID] = outcome
            }
            return stores.compactMap { ordered[$0.id] }
        }
    }

    @inlinable
    internal func p_store(
        _ entry: CacheEntry<Value>,
        for key: Key,
        route: P_CompiledRoute
    ) async throws
    {
        let mutations = p_stores.map { store in
            if route.writeStoreIDs.contains(store.id)
            {
                P_Mutation.store(store, entry, .store)
            }
            else
            {
                P_Mutation.remove(store, .remove)
            }
        }
        let failures = await p_perform(mutations, for: key)
        guard !failures.isEmpty else { return }

        let rollback = p_stores.map { P_Mutation.remove($0, .rollback) }
        let rollbackFailures = await p_perform(rollback, for: key)
        throw CacheError.storeFailures(failures + rollbackFailures)
    }

    @inlinable
    internal func p_storeUpdatingResidentCopies(
        _ entry: CacheEntry<Value>,
        for key: Key,
        targeting storeID: CacheStoreID
    ) async throws
    {
        let outcomes = await p_read(p_stores, for: key)
        let failures = outcomes.compactMap { outcome -> CacheStoreFailure? in
            guard case let .failure(failure) = outcome else { return nil }
            return failure
        }
        guard failures.isEmpty else
        {
            throw CacheError.storeFailures(failures)
        }

        let previousEntries = outcomes.reduce(
            into: [CacheStoreID: CacheEntry<Value>]()
        ) { result, outcome in
            guard case let .value(id, previousEntry?) = outcome,
                  !previousEntry.isExpired() else { return }
            result[id] = previousEntry
        }
        let expiredStoreIDs: Set<CacheStoreID> = Set(
            outcomes.compactMap { outcome -> CacheStoreID? in
            guard case let .value(id, previousEntry?) = outcome,
                  previousEntry.isExpired() else { return nil }
            return id
            }
        )
        let mutations = p_stores.compactMap { store -> P_Mutation? in
            if store.id == storeID || previousEntries[store.id] != nil
            {
                return .store(store, entry, .store)
            }
            if expiredStoreIDs.contains(store.id)
            {
                return .remove(store, .remove)
            }
            return nil
        }

        let mutationFailures = await p_perform(mutations, for: key)
        guard !mutationFailures.isEmpty else { return }

        let rollback = mutations.map { mutation -> P_Mutation in
            let store = mutation.store
            if let previousEntry = previousEntries[store.id]
            {
                return .store(store, previousEntry, .rollback)
            }
            return .remove(store, .rollback)
        }
        let rollbackFailures: [CacheStoreFailure] = await p_perform(
            rollback,
            for: key
        )
        throw CacheError.storeFailures(mutationFailures + rollbackFailures)
    }

    @inlinable
    internal func p_perform(
        _ mutations: [P_Mutation],
        for key: Key
    ) async -> [CacheStoreFailure]
    {
        guard mutations.count > 1 else
        {
            guard let mutation = mutations.first else { return [] }
            do
            {
                switch mutation
                {
                case let .store(store, entry, _):
                    try await store.p_store(entry, key)
                case let .remove(store, _):
                    try await store.p_remove(key)
                }
                return []
            }
            catch
            {
                return [CacheStoreFailure(
                    storeID: mutation.store.id,
                    operation: mutation.operation,
                    underlyingError: error
                )]
            }
        }

        return await withTaskGroup(
            of: P_CacheMutationOutcome.self,
            returning: [CacheStoreFailure].self
        ) { group in
            for mutation in mutations
            {
                group.addTask { [key, mutation] in
                    do
                    {
                        switch mutation
                        {
                        case let .store(store, entry, _):
                            try await store.p_store(entry, key)
                        case let .remove(store, _):
                            try await store.p_remove(key)
                        }
                        return .success(mutation.store.id)
                    }
                    catch
                    {
                        return .failure(CacheStoreFailure(
                            storeID: mutation.store.id,
                            operation: mutation.operation,
                            underlyingError: error
                        ))
                    }
                }
            }

            var outcomes: [CacheStoreID: P_CacheMutationOutcome] = [:]
            for await outcome in group
            {
                outcomes[outcome.storeID] = outcome
            }
            return mutations.compactMap { mutation in
                guard case let .failure(failure) = outcomes[mutation.store.id] else { return nil }
                return failure
            }
        }
    }

    // MARK: - Synchronous internals

    @inlinable
    internal func p_retrieveSynchronously(
        for key: Key,
        route: P_CompiledRoute
    ) throws -> CacheHit<Value>?
    {
        for stage in route.readStages
        {
            let outcomes = try p_readSynchronously(stage, for: key)
            let failures = outcomes.compactMap { outcome -> CacheStoreFailure? in
                guard case let .failure(failure) = outcome else { return nil }
                return failure
            }
            if route.readFailurePolicy == .fail, !failures.isEmpty
            {
                throw CacheError.storeFailures(failures)
            }

            for outcome in outcomes
            {
                guard case let .value(storeID, entry?) = outcome,
                      !entry.isExpired() else { continue }

                let hit = CacheHit(entry: entry, storeID: storeID)
                if let targets = route.promotions[storeID], !targets.isEmpty
                {
                    let mutations = targets.map {
                        P_Mutation.store($0, entry, .promote)
                    }
                    let promotionFailures = p_performSynchronously(
                        mutations,
                        for: key
                    )
                    if !promotionFailures.isEmpty
                    {
                        let rollback = targets.map {
                            P_Mutation.remove($0, .rollback)
                        }
                        let rollbackFailures = p_performSynchronously(
                            rollback,
                            for: key
                        )
                        if route.promotionFailurePolicy == .fail
                        {
                            throw CacheError.storeFailures(
                                promotionFailures + rollbackFailures
                            )
                        }
                    }
                }
                return hit
            }
        }
        return nil
    }

    @inlinable
    internal func p_readSynchronously(
        _ stores: [CacheStore<Key, Value>],
        for key: Key
    ) throws -> [P_CacheReadOutcome<Value>]
    {
        for store in stores where store.p_synchronous == nil
        {
            throw CacheError.synchronousAccessUnavailable(store.id)
        }
        guard !stores.isEmpty else { return [] }
        return stores.map { store in
            do
            {
                return .value(
                    store.id,
                    try store.p_synchronous!.p_retrieve(key)
                )
            }
            catch
            {
                return .failure(CacheStoreFailure(
                    storeID: store.id,
                    operation: .retrieve,
                    underlyingError: error
                ))
            }
        }
    }

    @inlinable
    internal func p_storeSynchronously(
        _ entry: CacheEntry<Value>,
        for key: Key,
        route: P_CompiledRoute
    ) throws
    {
        let mutations = p_stores.map { store in
            if route.writeStoreIDs.contains(store.id)
            {
                P_Mutation.store(store, entry, .store)
            }
            else
            {
                P_Mutation.remove(store, .remove)
            }
        }
        let failures = p_performSynchronously(mutations, for: key)
        guard !failures.isEmpty else { return }

        let rollback = p_stores.map { P_Mutation.remove($0, .rollback) }
        let rollbackFailures = p_performSynchronously(rollback, for: key)
        throw CacheError.storeFailures(failures + rollbackFailures)
    }

    @inlinable
    internal func p_storeUpdatingResidentCopiesSynchronously(
        _ entry: CacheEntry<Value>,
        for key: Key,
        targeting storeID: CacheStoreID
    ) throws
    {
        let outcomes = try p_readSynchronously(p_stores, for: key)
        let failures = outcomes.compactMap { outcome -> CacheStoreFailure? in
            guard case let .failure(failure) = outcome else { return nil }
            return failure
        }
        guard failures.isEmpty else
        {
            throw CacheError.storeFailures(failures)
        }

        let previousEntries = outcomes.reduce(
            into: [CacheStoreID: CacheEntry<Value>]()
        ) { result, outcome in
            guard case let .value(id, previousEntry?) = outcome,
                  !previousEntry.isExpired() else { return }
            result[id] = previousEntry
        }
        let expiredStoreIDs: Set<CacheStoreID> = Set(
            outcomes.compactMap { outcome -> CacheStoreID? in
            guard case let .value(id, previousEntry?) = outcome,
                  previousEntry.isExpired() else { return nil }
            return id
            }
        )
        let mutations = p_stores.compactMap { store -> P_Mutation? in
            if store.id == storeID || previousEntries[store.id] != nil
            {
                return .store(store, entry, .store)
            }
            if expiredStoreIDs.contains(store.id)
            {
                return .remove(store, .remove)
            }
            return nil
        }

        let mutationFailures = p_performSynchronously(mutations, for: key)
        guard !mutationFailures.isEmpty else { return }

        let rollback = mutations.map { mutation -> P_Mutation in
            let store = mutation.store
            if let previousEntry = previousEntries[store.id]
            {
                return .store(store, previousEntry, .rollback)
            }
            return .remove(store, .rollback)
        }
        let rollbackFailures: [CacheStoreFailure] = p_performSynchronously(
            rollback,
            for: key
        )
        throw CacheError.storeFailures(mutationFailures + rollbackFailures)
    }

    @inlinable
    internal func p_performSynchronously(
        _ mutations: [P_Mutation],
        for key: Key
    ) -> [CacheStoreFailure]
    {
        for mutation in mutations where mutation.store.p_synchronous == nil
        {
            return [CacheStoreFailure(
                storeID: mutation.store.id,
                operation: mutation.operation,
                underlyingError: CacheError.synchronousAccessUnavailable(
                    mutation.store.id
                )
            )]
        }
        return mutations.compactMap {
            p_performSynchronously($0, for: key)
        }
    }

    @inlinable
    internal func p_performSynchronously(
        _ mutation: P_Mutation,
        for key: Key
    ) -> CacheStoreFailure?
    {
        do
        {
            switch mutation
            {
            case let .store(store, entry, _):
                try store.p_synchronous!.p_store(entry, key)
            case let .remove(store, _):
                try store.p_synchronous!.p_remove(key)
            }
            return nil
        }
        catch
        {
            return CacheStoreFailure(
                storeID: mutation.store.id,
                operation: mutation.operation,
                underlyingError: error
            )
        }
    }

    @inlinable
    internal func p_performRemoveAllSynchronously() -> [CacheStoreFailure]
    {
        for store in p_stores where store.p_synchronous == nil
        {
            return [CacheStoreFailure(
                storeID: store.id,
                operation: .removeAll,
                underlyingError: CacheError.synchronousAccessUnavailable(store.id)
            )]
        }

        return p_stores.compactMap { store in
            do
            {
                try store.p_synchronous!.p_removeAll()
                return nil
            }
            catch
            {
                return CacheStoreFailure(
                    storeID: store.id,
                    operation: .removeAll,
                    underlyingError: error
                )
            }
        }
    }

    // MARK: - Isolation

    @inlinable
    internal func p_withSynchronousKeyAccess<Result>(
        _ key: Key,
        access: P_CacheReadWriteGate.Access,
        operation: () throws -> Result
    ) rethrows -> Result
    {
        p_globalGate.acquire(.read)
        let gate = p_keyGates.retainGate(for: key)
        gate.acquire(access)
        defer
        {
            gate.release(access)
            p_keyGates.releaseGate(gate, for: key)
            p_globalGate.release(.read)
        }
        return try operation()
    }

    @inlinable
    internal func p_withAsyncKeyAccess<Result: Sendable>(
        _ key: Key,
        access: P_CacheReadWriteGate.Access,
        operation: @Sendable () async throws -> Result
    ) async throws -> Result
    {
        try Task.checkCancellation()
        await p_globalGate.acquire(.read)
        if Task.isCancelled
        {
            p_globalGate.release(.read)
            throw CancellationError()
        }

        let gate = p_keyGates.retainGate(for: key)
        await gate.acquire(access)
        if Task.isCancelled
        {
            gate.release(access)
            p_keyGates.releaseGate(gate, for: key)
            p_globalGate.release(.read)
            throw CancellationError()
        }

        do
        {
            let result = try await operation()
            gate.release(access)
            p_keyGates.releaseGate(gate, for: key)
            p_globalGate.release(.read)
            return result
        }
        catch
        {
            gate.release(access)
            p_keyGates.releaseGate(gate, for: key)
            p_globalGate.release(.read)
            throw error
        }
    }
}
