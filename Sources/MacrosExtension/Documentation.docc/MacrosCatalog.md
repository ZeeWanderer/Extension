# Macros Catalog

A concise overview of the macros and supporting types exposed by this module.

## Overview

MacrosExtension provides code generation helpers that live at compile time. They are intended for application targets where you want declarative modeling without manually duplicating boilerplate. The catalog below lists the macros by intent; refer to source for expansion details.

### Enum and Snapshot Macros

- `@FlatEnum` for generating flat enum mirrors for case identification.
- `@ModelSnapshot`, `@SnapshotIgnore`, and `@SnapshotShallow` for SwiftData snapshot generation and selective exclusion.

### Actor Protocol Macros

- `@ActorProtocol`, `@ActorProtocolExtension(name:)`, and `@ActorProtocolIgnore` to standardize actor protocol surfaces and opt-out cases.

### Transaction Macros

- `@Transactional` overloads for ModelContext-backed transactional work.

### Logging Macros

- `@LogSubsystem` to generate `LogSubsystemProtocol` conformance with logger/signposter.
- `@LogCategory(subsystem:)` to generate `LogSubsystemCategoryProtocol` conformance and bind to a subsystem.

### Support Types

- `TransactionContext` for transactional execution context.
