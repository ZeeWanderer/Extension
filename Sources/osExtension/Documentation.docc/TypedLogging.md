# Typed Logging

Protocol-driven OSLog wiring without stringly typed subsystems.

## Overview

osExtension defines protocol requirements for log subsystems and categories. Conforming types centralize log identifiers so call sites can depend on types, not raw strings. A subsystem type provides `logger`/`signposter`, and category types build on that subsystem.

By default, `LogSubsystemProtocol.bundle` resolves to `Bundle.main.bundleIdentifier`, so subsystem IDs follow the host (app or app extension) rather than the package. If you want a fixed identifier (e.g. a framework or service domain), override `bundle` or `subsystem` in your subsystem type.

Prefer `static let` for the loggers/signposters so they’re initialized once. The protocols can’t enforce `let` vs `var` in Swift, so this is a convention you must follow. If you want enforcement, use a lint rule or code review checklist.

## Example

```swift
import osExtension
import os
import MacrosExtension

enum AppLog: LogSubsystemProtocol
{
    nonisolated static let logger = makeLogger()
    nonisolated static let signposter = makeSignposter()
}

enum NetworkLog: LogSubsystemCategoryProtocol<AppLog>
{
    nonisolated static let logger = makeLogger()
    nonisolated static let signposter = makeSignposter()
}

AppLog.logger.info("\(AppLog.logScope, privacy: .public) boot")
NetworkLog.logger.debug("\(NetworkLog.logScope, privacy: .public) request id=\(requestID, privacy: .public)")

@LogSubsystem
enum MacroAppLog {}

@LogCategory(subsystem: MacroAppLog.self)
enum MacroNetworkLog {}

MacroAppLog.logger.info("\(MacroAppLog.logScope, privacy: .public) boot")
MacroNetworkLog.logger.debug("\(MacroNetworkLog.logScope, privacy: .public) request id=\(requestID, privacy: .public)")

// Override subsystem IDs if you need a stable domain regardless of host bundle.
enum FixedSubsystem: LogSubsystemProtocol
{
    nonisolated static let logger = makeLogger()
    nonisolated static let signposter = makeSignposter()
    nonisolated static let bundle = "com.yourcompany.extension"
    nonisolated static let subsystem = "\(bundle).core"
}
```
