# ``SwiftUIExtension``

SwiftUI utilities for layout, view modifiers, SpriteKit bridging, and environment helpers.

## Overview

SwiftUIExtension focuses on pragmatic UI plumbing: convenience views, timeline helpers, keyboard height tracking, and lightweight extensions to common SwiftUI types like `View`, `Color`, `GeometryProxy`, and `UnitPoint`. It is designed to be dropped into app targets without introducing view framework coupling elsewhere.

## Topics

### Views and Modifiers

- ``ClearBackgroundView``
- ``ClearBackgroundViewModifier``
- ``LazyView``
- ``SpriteViewBuilder``
- ``Shadow``

### Environment and State

- ``KeyboardHeightHelper``
- ``SafeAreaInsetsKey``

### Animation and Timelines

- ``CyclicTimelineSchedule``

### SpriteKit Bridging

- ``SKSceneSwiftUI``

### Router APIs

- ``RouterDestination``
- ``RouterProtocol``
- ``SinglePathRouterProtocol``
- ``DictionaryRouterProtocol``
- ``RouterViewProvider``
- ``RouterViewRegistryProtocol``
- ``RouterDestinationModel``
- ``RouterDestinationView``
- ``RouterDestinationContext``
- ``RouterNavigationOperation``
- ``RouterNavigationEvent``
- ``RouterPushOptions``
- ``RouterPathSearchDirection``
- ``RouterSinglePathID``
- ``RouterViewRegistrationConflictPolicy``

### Guides

- <doc:ViewUtilities>
- <doc:Routing>
