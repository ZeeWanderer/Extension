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

## Compatibility

The package follows semantic versioning. Source-breaking changes ship only in a
major release. A deprecated API is normally removed in the second major release
following the release that first shipped its deprecation annotation.

Every major release adds a section to <doc:MigrationGuide>. Keep each historical
section intact so a client can start at its installed version and apply all
later sections in order.
