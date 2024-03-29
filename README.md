# Extension

An extension of `Foundation`, `CoreGraphics`, `UIKit`, `SwiftUI` and `SpriteKit` frameworks i use across my projects.

Some features to remeber:
## Foundation

`LocalizationDictionary`  
`Calendar.dateComponentDifference`  
`String.condenseWhitespace`  

## CoreGraphics

`CGPoint.translate`  
`CGPoint.translateBy`  
`CGSize.square`  
`CGSize.center`  
`CGRect.center`  

```swift
let point = CGPoint.zero * 5
let point = CGPoint.zero / 5
```

## UIKit

### CollectionViews
```swift
class CellClass: UICollectionViewCell, ReusableView {}

collectionView.register(CellClass.self)
let cell: CellClass = collectionView.dequeueReusableCell(forIndexPath: indexPath)
```

## SwiftUI

### Environment

```swift
@Environment(\.safeAreaInsets) var safeAreaInsets
```

`View.onNotification`  
`View.onDidEnterBackgroundNotification`  
`View.onWillEnterForegroundNotification`  
`View.glow`  
`View.debugRect`  
`View.debugBorder`  

## SpriteKit

`SKScene.screenShot_composite`  
