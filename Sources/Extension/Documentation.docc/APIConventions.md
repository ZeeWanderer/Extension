# API Conventions

Naming and compatibility conventions shared by every Extension module.

## Naming

Public and production APIs follow the standard Apple Swift naming conventions:
types use `UpperCamelCase`, while functions, properties, variables, argument
labels, and enum cases use `lowerCamelCase` and read naturally at the call site.

Snake-case identifiers are reserved for debug-only helpers whose spelling makes
their conditional or diagnostic purpose immediately visible, such as
`debug_print` and `debug_action`. New non-debug APIs must not use snake case.
Legacy exceptions can remain until they receive an intentional major-version
migration.

### Implementation-only declarations

Implementation-only declarations that remain visible inside a module use a
prefix matching the declaration's normal casing: `P_` for UpperCamelCase names,
such as `P_CacheReadWriteGate`, and `p_` for lower-camel-case or snake-case
names, such as `p_storage`. The prefix makes it clear that an `internal` or
`@usableFromInline` declaration is private to the library's implementation even
when `@testable import` or generated interfaces make the symbol visible.

Members already scoped inside a `P_` type do not repeat the prefix. Local
variables also keep ordinary lower-camel-case names. Language-defined names
such as initializers, deinitializers, subscripts, operators, overrides, and
protocol witnesses retain the spelling required by Swift.

Prefer an internal `P_` or `p_` declaration over `private` or `fileprivate` for
library implementation. `@usableFromInline` does not make such a declaration
supported public API; it only permits an `@inlinable` public body to reference
it.

## Concurrency

Every package target enables `NonisolatedNonsendingByDefault`. An ordinary
nonisolated async function therefore keeps the caller's actor isolation rather
than implicitly moving to the generic executor.

Use `@concurrent` at async API boundaries that must leave the caller's actor,
such as JSON coding and cache operations. This changes execution isolation,
not task ownership: execution remains in the calling task, preserving task-local
values, priority, and cancellation. Internal helpers normally inherit the
execution context selected by that boundary. UI operations stay on `MainActor`;
observation and suspension-only helpers preserve their required caller isolation.

Use `async let` or task groups for parallel work whose lifetime belongs to the
current operation. Creating `Task {}` or `Task.detached` and awaiting `.value`
does not make that task a structured child. Unstructured work needs an explicit
owner and lifetime, such as a synchronous-to-async bridge, an object-owned
notification subscription, or coalesced cache maintenance and persistence.

## Compatibility

The package follows semantic versioning. Source-breaking changes ship only in a
major release. A deprecated API is normally removed in the second major release
following the release that first shipped its deprecation annotation.

Every major release adds a section to <doc:MigrationGuide>. Keep each historical
section intact so a client can start at its installed version and apply all
later sections in order.
