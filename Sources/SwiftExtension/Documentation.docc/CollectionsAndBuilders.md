# Collections and Builders

Practical use of the small data structures and dictionary builder utilities.

## Overview

SwiftExtension ships lightweight containers and a `DictionaryBuilder` result-builder for constructing dictionaries without intermediate mutations. Use these when you want predictable performance and small APIs.

## Example

```swift
import SwiftExtension

var stack = Stack<Int>()
stack.push(1)
stack.push(2)
let top = stack.pop()

let payload: [String: Int] = makeDictionary {
    ["gold": 10]
    if top != nil {
        ["lastPopped": top ?? 0]
    }
}
```

`Queue` is backed by a linked list and uses copy-on-write so copied queues retain
value semantics. `FastQueue` is the array-backed choice for throughput-sensitive
FIFO work. `HashedHeap` stores unique values: repeated inserts are no-ops, input
arrays keep only their first occurrence, and its public index map stays aligned
after replacement and removal.
