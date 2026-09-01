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
    internal final class P_ContinuationBox: AtomicReference, Sendable
    {
        @usableFromInline let continuation: CheckedContinuation<Value, Failure>
        @usableFromInline init(_ continuation: CheckedContinuation<Value, Failure>)
        { self.continuation = continuation }
    }

    @usableFromInline internal let p_continuationRef: ManagedAtomic<P_ContinuationBox?>
    @usableFromInline internal let p_onDuplicateResume: @Sendable () -> Void

    /// Creates a guarded wrapper around `continuation`.
    ///
    /// - Parameters:
    ///   - continuation: The checked continuation to guard.
    ///   - onDuplicateResume: A closure invoked when a duplicate resume attempt
    ///     is ignored.
    @inlinable
    public init(_ continuation: CheckedContinuation<Value, Failure>, onDuplicateResume: @escaping @Sendable () -> Void = {})
    {
        self.p_continuationRef = ManagedAtomic(P_ContinuationBox(continuation))
        self.p_onDuplicateResume = onDuplicateResume
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
    { p_takeContinuation()?.resume(returning: value) }

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
    { p_takeContinuation()?.resume(throwing: error) }

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
    { p_takeContinuation()?.resume() }

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
    { p_takeContinuation()?.resume(with: result) }

    @usableFromInline
    internal func p_takeContinuation() -> CheckedContinuation<Value, Failure>?
    {
        let continuation = p_continuationRef.exchange(nil, ordering: .acquiringAndReleasing)?.continuation

        guard let continuation else {
            p_onDuplicateResume()
            return nil
        }

        return continuation
    }
}
