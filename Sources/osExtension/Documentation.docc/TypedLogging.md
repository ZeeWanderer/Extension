# Typed Logging

Protocol-driven OSLog wiring without stringly typed subsystems.

## Overview

osExtension defines protocol requirements for log subsystems and categories. Conforming types centralize log identifiers so call sites can depend on types, not raw strings. A subsystem type provides `logger`/`signposter`, and category types can build on that subsystem.

## Example

```swift
import osExtension
import os

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
NetworkLog.logger.debug("\(NetworkLog.logScope, privacy: .public) request")
```
