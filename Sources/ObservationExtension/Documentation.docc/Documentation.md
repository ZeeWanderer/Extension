# ``ObservationExtension``

Observation helpers for bridging state to async sequences and storage-backed updates.

## Overview

ObservationExtension provides protocols and async utilities that integrate with the Observation framework. Use it to expose Observable state changes as async sequences and to standardize state persistence. When `KeychainSwift` is available, it also provides a Keychain-backed observable protocol.

## Topics

### Observable Protocols

- ``ObservableCore``
- ``UserDefaultsObservable``

### Async Observation

- ``Observe_``
- ``MainActorObserve_``
