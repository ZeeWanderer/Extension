# Reusable Views and Scaling

Reusable view registration and device-specific sizing helpers.

## Overview

UIKitExtension provides `ReusableView`/`NibLoadableView` to standardize reuse identifiers and nib loading, plus `selectValue`/`scaleValue` helpers to tune layouts by device class without branching everywhere.

## Example

```swift
import UIKitExtension

final class HeroCell: UITableViewCell, ReusableView {}

tableView.register(HeroCell.self)
let cell: HeroCell = tableView.dequeueReusableCell(for: indexPath)

let cornerRadius = selectValue(universal: 8, pad: 16)
```
