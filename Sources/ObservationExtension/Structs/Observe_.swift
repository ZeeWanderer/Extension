//
//  Observe_.swift
//  Extension
//
//  Created by zeewanderer on 09.04.2025.
//

import Observation

/// Allows to continually observe a tracked property on an Observed class.
/// Eventually will be replaced by `Observe` from [`SE-0475`](https://github.com/phausler/swift-evolution/blob/80d70e41fb932f414505437bd78fa2ea216d46d8/proposals/0475-observed.md)
@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
public struct Observe_<V: Sendable>: AsyncSequence, AsyncIteratorProtocol
{
    @usableFromInline
    internal let apply: @isolated(any) () -> V
    @usableFromInline
    internal let castApply: (@Sendable () -> V)?
    
    @inlinable
    public init(of apply: @isolated(any) @escaping () -> V) {
        self.apply = apply
        let apply = self.apply as () -> V
        
        castApply = unsafeBitCast(apply, to: (@Sendable () -> V).self)
    }
    
    @inlinable
    public mutating func next() async  -> Bool?
    {
        guard let castApply else {
            return nil
        }
        
        await withCheckedContinuation(isolation: apply.isolation) { continuation in
            withObservationTracking {
                _ = castApply()
            } onChange: {
                continuation.resume()
            }
        }
        
        return true
    }
    
    @inlinable
    public func makeAsyncIterator() -> Self {
        self
    }
}

@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
public struct MainActorObserve_<V: Sendable>: AsyncSequence, AsyncIteratorProtocol
{
    @usableFromInline
    internal let apply: @MainActor () -> V
    
    @inlinable
    public init(of apply: @MainActor @escaping () -> V) {
        self.apply = apply
    }
    
    @MainActor @inlinable
    public mutating func next() async  -> Bool?
    {
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = apply()
            } onChange: {
                continuation.resume()
            }
        }
        
        return true
    }
    
    @inlinable
    public func makeAsyncIterator() -> Self {
        self
    }
}
