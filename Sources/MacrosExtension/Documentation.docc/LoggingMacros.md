# Logging Macros

Boilerplate-free conformance for typed OSLog subsystems and categories.

## Overview

Use `@LogSubsystem` to add `LogSubsystemProtocol` conformance with `logger`/`signposter`. Use `@LogCategory(subsystem:)` to add `LogSubsystemCategoryProtocol` conformance and bind to a subsystem type.

## Example

```swift
import osExtension
import MacrosExtension

@LogSubsystem
public enum AppLog {}

@LogCategory(subsystem: AppLog.self)
public enum NetworkLog {}

AppLog.logger.info("\(AppLog.logScope, privacy: .public) boot")
NetworkLog.logger.debug("\(NetworkLog.logScope, privacy: .public) request")
```

## Expansion

```swift
public enum AppLog {}

extension AppLog: LogSubsystemProtocol {
    public nonisolated static let logger = makeLogger()
    public nonisolated static let signposter = makeSignposter()
}

public enum NetworkLog {}

extension NetworkLog: LogSubsystemCategoryProtocol {
    public typealias Subsystem = AppLog
    public nonisolated static let logger = makeLogger()
    public nonisolated static let signposter = makeSignposter()
}
```
