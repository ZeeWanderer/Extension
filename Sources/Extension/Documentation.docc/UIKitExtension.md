# UIKitExtension

UIKit utilities for view reuse, layout scaling, feedback, and view capture.

## Overview

UIKitExtension targets practical UI work: reusable view registration, nib loading, device-specific scaling, and haptics helpers. Most APIs are thin wrappers around UIKit with consistent naming and minimal overhead. It also extends core UIKit types like `UIView`, `UIApplication`, and `UIScreen`.

## Topics

### View Reuse and Nibs

- ``ReusableView``
- ``NibLoadableView``

### Feedback and Interaction

- ``FeedbackHelper``
- ``debug_rect(_:color:)``

### Device-Specific Scaling

- ``selectValue(universal:phone:pad:mac:tv:carPlay:vision:)-(()->V,_,_,_,_,_,_)``
- ``scaleValue(universal:phone:pad:mac:tv:carPlay:vision:)-(_,CGFloat?,_,_,_,_,_)``
- ``adjustAttributesToFit(line:in:m_attributes:options:context:)``
