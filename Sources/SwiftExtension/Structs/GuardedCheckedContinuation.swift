//
//  GuardedCheckedContinuation.swift
//  Extension
//
//  Created by zeewanderer on 03.04.2026.
//

import Atomics

/// A wrapper for a checked continuation that guards against duplicate resumes.
///
/// A guarded continuation may be resumed at most once through this value.
/// Duplicate resume attempts are ignored, and invoke `onDuplicateResume`.
public struct GuardedCheckedContinuation<Value, Failure: Error>: Sendable
{
    @usableFromInline
    internal final class ContinuationBox: AtomicReference, Sendable
    {
        @usableFromInline let continuation: CheckedContinuation<Value, Failure>
        @usableFromInline init(_ continuation: CheckedContinuation<Value, Failure>)
        { self.continuation = continuation }
    }
    
    @usableFromInline internal let continuationRef: ManagedAtomic<ContinuationBox?>
    @usableFromInline internal let onDuplicateResume: @Sendable () -> Void
    
    /// Creates a guarded wrapper around `continuation`.
    ///
    /// - Parameters:
    ///   - continuation: The checked continuation to guard.
    ///   - onDuplicateResume: A closure invoked when a duplicate resume attempt
    ///     is ignored.
    @inlinable
    public init(_ continuation: CheckedContinuation<Value, Failure>, onDuplicateResume: @escaping @Sendable () -> Void = {})
    {
        self.continuationRef = ManagedAtomic(ContinuationBox(continuation))
        self.onDuplicateResume = onDuplicateResume
    }
    
    /// Calls the given closure with this guarded continuation.
    ///
    /// Copies of this value share the same underlying guard.
    ///
    /// - Parameter body: A closure that takes this guarded continuation as its
    ///   argument.
    @_transparent
    public func run(_ body: (GuardedCheckedContinuation<Value, Failure>) -> Void)
    { body(self) }
    
    /// Resume the task awaiting the continuation by having it return normally
    /// from its suspension point.
    ///
    /// - Parameter value: The value to return from the continuation.
    ///
    /// A guarded continuation may be resumed at most once through this object.
    /// If it has already been resumed, the duplicate attempt is ignored and
    /// `onDuplicateResume` is invoked.
    ///
    /// After `resume` enqueues the task, control immediately returns to
    /// the caller. The task continues executing when its executor is
    /// able to reschedule it.
    @_transparent public func resume(returning value: sending Value)
    { takeContinuation()?.resume(returning: value) }
    
    /// Resume the task awaiting the continuation by having it throw an error
    /// from its suspension point.
    ///
    /// - Parameter error: The error to throw from the continuation.
    ///
    /// A guarded continuation may be resumed at most once through this object.
    /// If it has already been resumed, the duplicate attempt is ignored and
    /// `onDuplicateResume` is invoked.
    ///
    /// After `resume` enqueues the task, control immediately returns to
    /// the caller. The task continues executing when its executor is
    /// able to reschedule it.
    @_transparent public func resume(throwing error: Failure)
    { takeContinuation()?.resume(throwing: error) }

    /// Resume the task awaiting the continuation by having it return normally
    /// from its suspension point.
    ///
    /// A guarded continuation may be resumed at most once through this object.
    /// If it has already been resumed, the duplicate attempt is ignored and
    /// `onDuplicateResume` is invoked.
    ///
    /// After `resume` enqueues the task, control immediately returns to
    /// the caller. The task continues executing when its executor is
    /// able to reschedule it.
    @_transparent public func resume() where Value == Void
    { takeContinuation()?.resume() }
    
    /// Resume the task awaiting the continuation by having it either
    /// return normally or throw an error based on the state of the given
    /// `Result` value.
    ///
    /// - Parameter result: A value to either return or throw from the
    ///   continuation.
    ///
    /// A guarded continuation may be resumed at most once through this object.
    /// If it has already been resumed, the duplicate attempt is ignored and
    /// `onDuplicateResume` is invoked.
    ///
    /// After `resume` enqueues the task, control immediately returns to
    /// the caller. The task continues executing when its executor is
    /// able to reschedule it.
    @_transparent public func resume(with result: sending Result<Value, Failure>)
    { takeContinuation()?.resume(with: result) }
    
    @usableFromInline
    internal func takeContinuation() -> CheckedContinuation<Value, Failure>?
    {
        let continuation = continuationRef.exchange(nil, ordering: .acquiringAndReleasing)?.continuation
        
        guard let continuation
        else {
            onDuplicateResume()
            return nil
        }
        
        return continuation
    }
}
