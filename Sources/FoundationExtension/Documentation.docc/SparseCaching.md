# Sparse and Shared Disk Caching

Cache large resources by byte range while sharing one physical disk budget with
ordinary cached values.

## Overview

``DiskCacheStorage`` owns a directory, its allocated-byte accounting, recency,
maintenance policy, and process-local file barriers. One ordinary disk
``CacheStore`` and any number of named ``SparseCache`` namespaces can share that
storage.

``SparseCache`` is intentionally not a ``CacheStore``. A partial byte range is
not a complete `Value`, so generic reads and promotions could incorrectly treat
an incomplete resource as a cache hit. The sparse facade instead exposes range
operations, while shared storage coordinates only physical concerns such as
capacity and eviction.

## Choose a storage location

Use ``DiskCacheLocation/cachesDirectory`` for replaceable downloads. Use
``DiskCacheLocation/applicationSupportDirectory(excludesFromBackup:)`` when the
system cache directory may be purged but the data should remain until explicit
maintenance. Replaceable data in Application Support is excluded from backup by
default. Temporary storage makes no persistence guarantee.

An App Group or custom parent is also supported:

```swift
let storage = try DiskCacheStorage(
    name: "media",
    location: .appGroup(
        "group.com.example.application",
        directory: .caches
    )
)
```

Synchronization is process-local. An App Group location can retain the same
files for an app and extension, but the two processes must not operate on that
storage simultaneously without an external process-level exclusion mechanism.
The storage directory is exclusively managed; do not add or mutate files through
``DiskCacheStorage/directoryURL``.

`Cache` has no global directory because its stores may be memory, database, or
remote implementations. To organize several disk stores below one application
directory, give each storage a distinct name under the same custom parent:

```swift
let root = URL.applicationSupportDirectory
    .appending(component: "Downloaded Content", directoryHint: .isDirectory)

let imageStorage = try DiskCacheStorage(
    name: "images",
    location: .custom(root, excludesFromBackup: true)
)
let videoStorage = try DiskCacheStorage(
    name: "videos",
    location: .custom(root, excludesFromBackup: true)
)
```

## Cache byte ranges

Prepare the logical resource before writing ranges. A change in capacity or
`generation` discards every old range. For an HTTP resource, use an ETag,
Last-Modified value, or another server version as the generation.

Available bytes are immutable within one generation. An overlapping insertion
writes only missing gaps, making retries idempotent and preventing a failed or
interrupted retry from damaging bytes already advertised as valid. Change the
generation when the resource content changes.

```swift
let storage = try DiskCacheStorage(name: "media")
let videos = try SparseCache<String>(storage: storage)

let state = try await videos.prepare(
    capacity: contentLength,
    generation: etag.data(using: .utf8),
    metadata: responseMetadata,
    forKey: resourceURL.absoluteString
)

for missingRange in state.missingRanges(in: requestedRange) {
    let bytes = try await download(missingRange)
    try await videos.insert(
        bytes,
        at: missingRange.lowerBound,
        forKey: resourceURL.absoluteString
    )
}

let bytes = try await videos.data(
    in: requestedRange,
    forKey: resourceURL.absoluteString
)
```

A read succeeds only when every requested byte is present. Use
``SparseCacheSnapshot/missingRanges(in:)`` to plan fetches and
``SparseCacheSnapshot/contiguousRange(in:from:maximumLength:)`` to answer a
streaming request with the currently available contiguous prefix.

## Understand range isolation

Each sparse resource has an interval-aware access boundary:

- Reads may overlap other reads.
- A read and write may proceed together when their ranges are disjoint.
- Disjoint writes may proceed together.
- An overlapping write waits for every intersecting read or write.
- Preparation, removal, synchronization, and eviction exclude the whole
  resource.

The implementation uses positional file I/O, so concurrent operations do not
share or race a mutable file offset. Manifest updates have a separate serialized
boundary and are atomically replaced. A range is added to the manifest only
after every missing byte has been written, so failed or interrupted writes are
never advertised as valid.

`synchronize(forKey:)` flushes the latest range manifest and synchronizes both
the sparse data file and manifest. Ordinary inserts coalesce manifest writes for
throughput; use explicit synchronization before a durability boundary that
cannot tolerate the coalescing delay.

## Keep targeted object writes coherent

Targeted access to an ordinary registered store remains an operation on
``Cache``, not direct backend access. A targeted read inspects exactly one store
without promotion:

```swift
let diskValue = try await cache.value(forKey: key, from: "disk")
```

A targeted write always updates the requested store and every other store that
already contains an unexpired copy. Truly absent stores remain absent. This
allows a disk-only placement request without leaving an older promoted memory
copy behind:

```swift
try await cache.insert(updatedValue, forKey: key, targeting: "disk")
```

Before mutation, the dispatcher reads every registered store to determine
residency. A read failure aborts the operation. A mutation failure triggers a
best-effort restoration of the prior resident set and is reported through
``CacheError/storeFailures(_:)``. Raw single-store mutation and targeted removal
are not exposed because they could make an older copy visible through another
route.

Sparse entries do not participate in this object-value coherence rule. Do not
use an ordinary cache entry and a sparse entry as independently mutable copies
of the same logical value. Use the sparse facade as that resource's authority,
or explicitly version and invalidate the other representation in application
code.

## Maintain shared storage

Forced maintenance invoked on ``DiskCacheStorage`` scans ordinary object files
and all sparse namespaces under one allocated-byte capacity policy:

```swift
let result = try await storage.performMaintenance(.forced)
```

The scan rebuilds a shared in-memory inventory. Later capacity crossings use
that inventory without enumerating every object and sparse file again. Stale
and expired entries are removed with per-resource exclusion, so unrelated keys
continue operating. Capacity planning briefly takes a storage-wide write
boundary to select and apply one deterministic LRU plan. Preferred and emergency
watermark triggers are independently edge-triggered. Recent-use protection can
leave storage above its preferred target without repeatedly scheduling work,
but it is ignored above the configured maximum or during aggressive maintenance.

`Cache.removeAll()` removes values owned by that dispatcher and deliberately
leaves specialized namespaces untouched. `SparseCache.removeAll()` removes only
its namespace. ``DiskCacheStorage``'s `removeAll()` is the explicit destructive
operation that removes every object and sparse entry in the physical storage.

For custom ``CacheStore`` implementations, maintenance remains a store-owned
closure and may use ``CacheCapacityPolicy`` with any consistent capacity unit.
Custom backends should use their own directory rather than writing private files
inside a ``DiskCacheStorage`` directory.

## See Also

- [About Apple File System](https://developer.apple.com/documentation/foundation/about-apple-file-system)
- [Using the File System Effectively](https://developer.apple.com/documentation/foundation/using-the-file-system-effectively)
- [FileManager containerURL(forSecurityApplicationGroupIdentifier:)](https://developer.apple.com/documentation/foundation/filemanager/containerurl%28forsecurityapplicationgroupidentifier%3A%29)
