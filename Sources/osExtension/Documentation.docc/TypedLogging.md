# Typed Logging

Protocol-driven OSLog wiring without stringly typed subsystems.

## Overview

osExtension defines protocol requirements for log subsystems and categories. Conforming types centralize log identifiers so call sites can depend on types, not raw strings.

## Example

```swift
import osExtension
import os

enum AppLog: LogSubsystemProtocol
{
    static let subsystem = "com.example.app"
}

extension AppLog
{
    static var network: OSLog { OSLog(subsystem: subsystem, category: "network") }
}
```
