# Routed Caching

Compose memory, disk, and custom stores behind one per-key isolation boundary.

## Overview

``Cache`` is a dispatcher over any number of ``CacheStore`` values. A route
selects where a key is read, written, and promoted without exposing individual
stores for out-of-band mutation.

> Important: The routed cache API requires iOS 18.4, Mac Catalyst 18.4, or
> macOS 15.4. Other FoundationExtension APIs retain the package's lower
> deployment targets.

The async API is the primary API. Waiting for another operation suspends the
current Swift task, so it does not occupy a cooperative executor thread. Stores
within one read stage run as structured child tasks. The built-in disk store
runs blocking Foundation file I/O on a dedicated utility `TaskExecutor` rather
than Swift's cooperative global executor.

The synchronous overloads use the same isolation boundaries but block the
calling thread. They do not create tasks or dispatch nested work; stores are
visited in route order. Multiple synchronous callers can still overlap when
the per-key isolation rules permit it. The overloads are unavailable from
async contexts and should be used only by genuinely synchronous callers.

## Use an in-memory cache

The convenience initializer creates one `NSCache`-backed store:

```swift
let cache = Cache<String, Data>(
    memoryConfiguration: .init(
        countLimit: 1_000,
        totalCostLimit: 64 * 1024 * 1024
    ),
    cost: \Data.count
)

try await cache.insert(payload, forKey: key)
let payload = try await cache.value(forKey: key)
```

The same calls are blocking when made from a synchronous function:

```swift
try cache.insert(payload, forKey: key)
let payload = try cache.value(forKey: key)
```

## Compose memory and disk stores

Store identifiers are local to one dispatcher. The default route treats the
initializer order as a fastest-to-slowest hierarchy: reads search each store in
order, writes target every store, and slower hits promote to all preceding
stores.

```swift
let primaryMemory = CacheStore<String, Data>.memory(
    id: "primary-memory",
    configuration: .init(totalCostLimit: 64 * 1024 * 1024),
    cost: \Data.count
)
let secondaryMemory = CacheStore<String, Data>.memory(
    id: "secondary-memory",
    configuration: .init(totalCostLimit: 256 * 1024 * 1024),
    cost: \Data.count
)
let disk = try CacheStore<String, Data>.disk(
    id: "disk",
    configuration: .init(name: "images")
)

let cache = try Cache(stores: [
    primaryMemory,
    secondaryMemory,
    disk,
])
```

Each disk directory can belong to only one live dispatcher. Give unrelated disk
caches distinct names or root directories.

## Customize routing and promotion

A ``CacheRoute`` consists of ordered read stages, write destinations, and
promotion destinations:

- Read stages run in sequence.
- Async operations query stores inside one stage concurrently. Their array
  order is the deterministic priority when more than one returns a value.
- Synchronous operations query stores inside one stage in array order.
- A write updates every selected store and removes the key from every
  nonselected store, preventing an older copy from resurfacing through another
  route.
- A hit is promoted only to the targets configured for its source store.

This route reads the primary memory first, then races the secondary memory and
disk. Either slower hit promotes only to the primary memory:

```swift
let route = CacheRoute(
    readStages: [
        ["primary-memory"],
        ["secondary-memory", "disk"],
    ],
    writeStores: ["secondary-memory", "disk"],
    promotions: [
        "secondary-memory": ["primary-memory"],
        "disk": ["primary-memory"],
    ]
)

let value = try await cache.value(forKey: key, route: route)
```

To inspect one registered store without promotion, use a targeted read. A
targeted write updates the requested store and every unexpired resident copy,
while leaving stores that are genuinely absent unchanged:

```swift
let persisted = try await cache.value(forKey: key, from: "disk")
try await cache.insert(updated, forKey: key, targeting: "disk")
```

The dispatcher determines residency across all stores before changing any of
them. It therefore aborts when a store cannot be read and performs best-effort
restoration when a mutation fails. This operation is distinct from a route
write, which intentionally invalidates every destination outside the route.

Pass a fixed route to the initializer when every key shares a policy; the cache
compiles it once. Pass a route provider to select a policy for every key, or
pass an override to one operation:

```swift
let cache = try Cache(
    stores: [primaryMemory, secondaryMemory, disk],
    routeProvider: { key in
        key.hasPrefix("temporary-")
            ? CacheRoute(
                readStages: [["primary-memory"]],
                writeStores: ["primary-memory"]
            )
            : .hierarchy(["primary-memory", "secondary-memory", "disk"])
    }
)
```

## Understand isolation and failures

Isolation applies to a key across the complete dispatcher, not to an individual
store:

- Read-only operations for the same key can overlap.
- A write excludes every read and write for that key until its cross-store
  mutation completes.
- A read route with promotions is also exclusive, so no caller observes a
  partially promoted value.
- Different keys remain independent.
- `removeAll()` is a dispatcher-wide barrier.

Maintenance is store-local eviction rather than an out-of-band cache write.
For example, a disk store can discard an old copy while a bounded memory store
still retains it. A later hierarchy lookup either uses the surviving faster
copy or falls through normally. Custom maintenance implementations must be safe
to overlap that store's ordinary operations.

If one destination rejects a write, the dispatcher makes a best-effort removal
from every store and reports ``CacheError/storeFailures(_:)``. Promotions can
either tolerate or report store failures through ``CacheFailurePolicy``.

Cancellation is checked before waiting and again before an async operation
enters its isolation boundary. A cancelled waiter does not start store work when
it reaches the front of the queue. Once a mutation has started, its stores are
allowed to finish or roll back so cancellation cannot intentionally leave a
partial hierarchy.

## Add a custom store

Create a ``CacheStore`` from concurrency-safe operations. Supply
``CacheStoreSynchronousOperations`` only when the backend has a genuine
blocking API:

```swift
let remote = CacheStore<String, Data>(
    id: "remote",
    retrieve: { key in
        try await backend.entry(for: key)
    },
    store: { entry, key in
        try await backend.store(entry, for: key)
    },
    remove: { key in
        try await backend.removeValue(forKey: key)
    },
    removeAll: {
        try await backend.removeAll()
    }
)
```

Async store operations must not perform blocking work on Swift's cooperative
executor. Move legacy file or database calls to an appropriate blocking
executor. Do not mutate the backend outside its dispatcher or reenter the same
dispatcher from a store closure.

The dispatcher deliberately does not require a store to expose enumeration,
cost metadata, or an LRU implementation. Those assumptions would make remote,
database, and content-addressed stores unnecessarily rigid. A custom store can
instead reuse ``CacheCapacityPolicy`` after taking an atomic snapshot in its
own capacity unit:

```swift
let policy = CacheCapacityPolicy.soft(
    preferredCapacity: 10_000,
    trimToCapacity: 7_500,
    maximumCapacity: 15_000,
    recentAccessProtectionInterval: 10 * 60
)

let store = CacheStore<String, Data>(
    id: "database",
    retrieve: { key in try await backend.entry(for: key) },
    store: { entry, key in try await backend.store(entry, for: key) },
    remove: { key in try await backend.removeValue(forKey: key) },
    removeAll: { try await backend.removeAll() },
    maintenance: { mode in
        let snapshot = try await backend.capacitySnapshot()
        let plan = policy.evictionPlan(
            currentCapacity: snapshot.totalPageCount,
            candidates: snapshot.entries.map {
                CacheCapacityPolicy.Candidate(
                    id: $0.key,
                    capacity: $0.pageCount,
                    lastAccessDate: $0.lastAccessDate
                )
            },
            allowsProtectedEviction: mode == .aggressive
        )
        try await backend.removeValues(
            forKeys: plan.evictions.map(\.id)
        )
        return CacheStoreMaintenanceResult(
            status: .completed,
            scannedEntryCount: snapshot.entries.count,
            removedEntryCount: plan.evictions.count,
            capacityUnit: "database-pages",
            removedCapacity: plan.evictions.reduce(0) {
                $0 + $1.capacity
            },
            remainingCapacity: plan.projectedCapacity,
            protectedEntryCount: plan.protectedEntryCount,
            protectedCapacity: plan.protectedCapacity,
            didExceedMaximumCapacity:
                plan.didExceedMaximumCapacity
        )
    }
)
```

The planner is optional. Stores with frequency-based, server-managed, or other
eviction policies can ignore it and still report their own capacity unit. The
store is responsible for applying a plan under the same backend isolation used
to create its snapshot; the dispatcher cannot make an opaque store-wide plan
atomic on its behalf.

## Maintain cache stores

Maintenance is an optional ``CacheStore`` capability. Run every configured
store or select stores by identifier. Selected stores execute concurrently and
the report retains the requested order:

```swift
let report = try await cache.performMaintenance(
    storeIDs: ["secondary-memory", "disk"],
    mode: .forced
)

let removedBytes = report[storeID: "disk"]?.removedCapacity
```

Use `ifNeeded` to respect each store's maintenance throttle. `forced` means
"scan now"; it still applies the configured expiration, age, and capacity
policies and does not remove otherwise valid entries. `aggressive` also scans
now and permits a store to override temporary protections, such as the disk
store's recent-use window. It does not bypass expiration, capacity, or backend
invariants. A store without a maintenance implementation reports `unsupported`.
Store failures throw by default, or can be collected in the report with
`failurePolicy: .ignore`.

When maintenance should begin now but be awaited later, keep the returned task:

```swift
let maintenance = cache.startMaintenance(mode: .ifNeeded)

// Continue unrelated work.

let report = try await maintenance.value
```

`startMaintenance` uses an unstructured utility-priority task and does not
inherit the caller's actor. Cancelling that task cooperatively cancels the
maintenance operation. The synchronous `performMaintenance` overload uses a
store's blocking maintenance operation and is available only from synchronous
contexts.

The built-in disk store can request maintenance automatically. Requests made
at store creation and after reads or mutations are coalesced; normal cache
operations do not await the resulting background job. Crossing the preferred
capacity schedules one indexed eviction pass and disarms that trigger until
storage falls below the preferred capacity again. The maximum capacity has an
independent emergency trigger. Remaining above either watermark therefore does
not create a write-evict-write scheduling loop.

```swift
let disk = try CacheStore<String, Data>.disk(
    configuration: .init(
        name: "images",
        capacityPolicy: .soft(
            preferredCapacity: 400 * 1024 * 1024,
            trimToCapacity: 300 * 1024 * 1024,
            maximumCapacity: 600 * 1024 * 1024,
            recentAccessProtectionInterval: 10 * 60
        ),
        minimumMaintenanceInterval: 60 * 60,
        minimumAccessDateUpdateInterval: 60,
        maximumUnusedInterval: 30 * 24 * 60 * 60,
        removesExpiredEntries: true,
        performsAutomaticMaintenance: true,
        maximumConcurrentMaintenanceOperations: 8
    )
)
```

`minimumMaintenanceInterval` controls full reconciliation and stale-entry
scans only. A reconciliation enumerates the directory once, repairs incremental
allocated-byte accounting, and rebuilds the in-memory eviction inventory.
Capacity crossings between reconciliations select candidates directly from that
inventory instead of recalculating directory size. A full pass removes eligible
corrupt, expired, and unused files with bounded concurrency. Those removals are
isolated per file, so normal operations on other disk keys can continue during
the age-based phase. Capacity uses allocated file size rather than serialized
payload size, matching the space consumed on disk.

Above the preferred capacity, the store removes least-recently-used entries
toward the lower trim target but temporarily protects recent entries. It can
therefore remain above the preferred value instead of evicting hot data and
immediately caching it again. Above the maximum capacity, protection is
unconditionally disabled and eviction proceeds toward the trim target. An
individual encoded entry larger than the hard ceiling is rejected before it
replaces an existing value. Set `capacityPolicy` to `.unlimited` when another
system owns disk capacity.

The store briefly takes its directory mutation boundary while it selects and
applies that deterministic capacity plan. Asynchronous callers targeting the
disk store suspend rather than observe a partially applied decision. Accesses
are reflected in memory immediately while persisted access-date writes are
throttled by `minimumAccessDateUpdateInterval`. Other stores and unrelated
application tasks remain independent. Remaining counts and capacity in the
report are completion-time observations and can immediately change when
ordinary cache operations continue concurrently.

For replaceable downloads on devices with very different storage capacities,
opt into startup-only adaptive sizing:

```swift
let storage = try DiskCacheStorage(
    name: "media",
    adaptiveCapacityPolicy: .init(
        usage: .opportunistic,
        maximumCapacity: 1024 * 1024 * 1024
    )
)
```

The policy queries the selected volume once. It includes the cache's existing
allocation in the available-space calculation, then freezes the resulting
preferred, trim, and maximum capacities for this storage lifetime. This avoids
a feedback loop where writing cache data continuously reduces the cache's own
budget. The regular 400 MiB / 300 MiB / 600 MiB policy remains the fallback when
the volume does not provide an estimate. Use `important` only for content needed
by an explicit user operation already in progress; predictive cache fills
should use `opportunistic`.

## Configure disk coding

The `String`/`Data` disk convenience uses UTF-8 key bytes and stores `Data`
directly. Other key and value types provide a ``CacheKeyEncoder`` and
``CacheValueCoder``:

```swift
let disk = try CacheStore<ModelID, Model>.disk(
    configuration: .init(name: "models"),
    keyEncoder: .json,
    valueCoder: .json
)
```

The key encoder must produce stable bytes for the lifetime of the disk cache.
Those bytes are SHA-256 hashed into collision-resistant file names. The cache
file envelope and eviction metadata are implementation details, not a public
serialization format.

Use ``DiskCacheStorage`` when an ordinary disk store and specialized byte-range
``SparseCache`` namespaces should share one directory budget and maintenance
boundary. See <doc:SparseCaching> for location, range isolation, durability, and
removal semantics.
