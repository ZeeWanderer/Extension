# Runtime Configuration

Simple environment checks for build and distribution channels.

## Overview

Use `Config` to branch behavior for debug builds, TestFlight, or App Store deployment without wiring up your own receipt checks.

## Example

```swift
import GeneralExtensions

if Config.isDebug {
    print("Debug-only diagnostics")
}
```
