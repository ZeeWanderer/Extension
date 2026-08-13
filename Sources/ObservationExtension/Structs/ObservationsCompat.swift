//
//  ObservationsCompat.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import Foundation
import Observation

// This implementation is adapted from Swift's Observations.swift.
// Copyright (c) 2025 Apple Inc. and the Swift project authors.
// Licensed under Apache License v2.0 with Runtime Library Exception.
// Modified in 2026 for Extension: renamed as a compatibility type, added
// system delegation, replaced Swift's internal critical-state primitive for
// older systems, and added legacy iterator support.

/// An asynchronous sequence of transactional changes to `@Observable` values.
///
/// `ObservationsCompat` uses `Observation.Observations` on version 26 and newer
/// systems and backports its behavior to the older deployment targets supported
/// by this package. The sequence immediately emits the value produced by
/// `emit`, then emits a new value after an observed dependency changes.
/// Mutations made within the same transaction are coalesced into one emission.
///
/// `Observe_` is an older, independent API and is not used by this type.
@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
public struct ObservationsCompat<Element: Sendable, Failure: Error>: AsyncSequence, Sendable {
    /// The result of one evaluation of an `untilFinished` producer.
    public enum Iteration: Sendable {
        /// Emits an element and continues observing.
        case next(Element)

        /// Finishes the sequence without emitting another element.
        case finish
    }

    internal struct P_State {
        internal enum Continuation {
            case cancelled
            case active(UnsafeContinuation<Void, Never>)

            func resume() {
                switch self {
                case .cancelled:
                    break
                case .active(let continuation):
                    continuation.resume()
                }
            }
        }

        internal var nextID = 0
        internal var continuations: [Int: Continuation] = [:]
        internal var isDirty = false

        static func generation(_ state: P_CriticalState<P_State>) -> Int {
            state.withCriticalRegion { state in
                defer { state.nextID &+= 1 }
                return state.nextID
            }
        }

        static func cancel(_ state: P_CriticalState<P_State>, id: Int) {
            let continuation = state.withCriticalRegion { state in
                guard let continuation = state.continuations.removeValue(forKey: id) else {
                    // Cancellation can race with continuation installation.
                    // Leave a tombstone so installation resumes immediately.
                    state.continuations[id] = .cancelled
                    return nil as Continuation?
                }

                return continuation
            }

            continuation?.resume()
        }

        static func emitWillChange(_ state: P_CriticalState<P_State>) {
            let continuations = state.withCriticalRegion { state in
                if state.continuations.isEmpty {
                    state.isDirty = true
                }

                let continuations = Array(state.continuations.values)
                state.continuations.removeAll()
                return continuations
            }

            for continuation in continuations {
                continuation.resume()
            }
        }

        static func removeContinuation(_ state: P_CriticalState<P_State>, id: Int) {
            let continuation = state.withCriticalRegion { state in
                state.continuations.removeValue(forKey: id)
            }
            continuation?.resume()
        }

        static func willChange(
            isolation: isolated (any Actor)? = #isolation,
            state: P_CriticalState<P_State>,
            id: Int
        ) async {
            await withUnsafeContinuation(isolation: isolation) { continuation in
                let continuationToResume = state.withCriticalRegion { state in
                    defer { state.isDirty = false }

                    switch state.continuations[id] {
                    case .cancelled:
                        return continuation as UnsafeContinuation<Void, Never>?
                    case .active:
                        fatalError("Iterator incorrectly shared across task isolations")
                    case .none:
                        if state.isDirty {
                            return continuation
                        }

                        state.continuations[id] = .active(continuation)
                        return nil
                    }
                }

                continuationToResume?.resume()
            }
        }
    }

    internal enum P_Emit: Sendable {
        case iteration(@isolated(any) @Sendable () throws(Failure) -> Iteration)
        case element(@isolated(any) @Sendable () throws(Failure) -> Element)

        var isolation: (any Actor)? {
            switch self {
            case .iteration(let closure):
                closure.isolation
            case .element(let closure):
                closure.isolation
            }
        }
    }

    internal enum P_Storage: Sendable {
        case compatibility(P_CriticalState<P_State>, P_Emit)

        #if compiler(>=6.2)
        case systemElements(P_UncheckedSendableStorage)
        case systemIterations(P_UncheckedSendableStorage)
        #endif
    }

    internal let p_storage: P_Storage

    #if compiler(>=6.2)
    /// Lets the package's tests exercise the compatibility backend on a host
    /// where system `Observations` is already available.
    internal static var p_shouldUseSystemObservations: Bool {
        #if EXTENSION_OBSERVATIONS_COMPAT_FORCE_FALLBACK
        false
        #else
        true
        #endif
    }
    #endif

    internal init(p_storage: P_Storage) {
        self.p_storage = p_storage
    }

    /// Creates a sequence that emits the current value and each subsequent
    /// transactional change to the observable dependencies read by `emit`.
    public init(
        @_inheritActorContext _ emit: @escaping @isolated(any) @Sendable () throws(Failure) -> Element
    ) {
        #if compiler(>=6.2)
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *),
           Self.p_shouldUseSystemObservations {
            p_storage = .systemElements(
                P_UncheckedSendableStorage(Observation.Observations(emit))
            )
        } else {
            p_storage = .compatibility(P_CriticalState(P_State()), .element(emit))
        }
        #else
        p_storage = .compatibility(P_CriticalState(P_State()), .element(emit))
        #endif
    }

    /// Creates a sequence whose producer can explicitly finish iteration.
    public static func untilFinished(
        @_inheritActorContext _ emit: @escaping @isolated(any) @Sendable () throws(Failure) -> Iteration
    ) -> ObservationsCompat<Element, Failure> {
        #if compiler(>=6.2)
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *),
           Self.p_shouldUseSystemObservations {
            return .init(
                p_storage: .systemIterations(
                    P_UncheckedSendableStorage(Observation.Observations(emit))
                )
            )
        }
        #endif

        return .init(
            p_storage: .compatibility(P_CriticalState(P_State()), .iteration(emit))
        )
    }

    internal struct P_CompatibilityIterator {
        internal var state: P_CriticalState<P_State>?
        internal let emit: P_Emit
        internal var hasStarted = false

        internal init(state: P_CriticalState<P_State>, emit: P_Emit) {
            self.state = state
            self.emit = emit
        }

        #if compiler(>=6.4)
        @diagnose(
            ConversionFromIsolatedAnyToSynchronous,
            as: ignored,
            reason: "https://github.com/swiftlang/swift/issues/89361"
        )
        #endif
        internal static func trackEmission(
            isolation: isolated (any Actor)?,
            state: P_CriticalState<P_State>,
            emit: P_Emit
        ) throws(Failure) -> Iteration {
            // The public tracking API cannot throw, so preserve the typed error
            // in a Result until observation registration is complete.
            let result: Result<Iteration, Failure> = withObservationTracking { () -> Result<Iteration, Failure> in
                do {
                    switch emit {
                    case .element(let element):
                        let extracted: () throws(Failure) -> Element = element
                        return .success(.next(try extracted()))
                    case .iteration(let iteration):
                        let extracted: () throws(Failure) -> Iteration = iteration
                        return .success(try extracted())
                    }
                } catch {
                    // Typed throws guarantees this cast; Swift currently
                    // erases the caught value to `any Error` in this context.
                    return .failure(error as! Failure)
                }
            } onChange: { [state] in
                P_State.emitWillChange(state)
            }

            return try result.get()
        }

        internal mutating func terminate(
            throwing failure: Failure? = nil,
            id: Int
        ) throws(Failure) -> Element? {
            if let state {
                P_State.removeContinuation(state, id: id)
            }
            state = nil

            if let failure {
                throw failure
            }

            return nil
        }

        internal mutating func trackEmission(
            isolation: isolated (any Actor)?,
            state: P_CriticalState<P_State>,
            id: Int
        ) async throws(Failure) -> Element? {
            guard !Task.isCancelled else {
                return try terminate(id: id)
            }

            switch try await Self.trackEmission(
                isolation: emit.isolation,
                state: state,
                emit: emit
            ) {
            case .finish:
                return try terminate(id: id)
            case .next(let element):
                return element
            }
        }

        internal mutating func nextValue(
            isolation: isolated (any Actor)? = #isolation
        ) async throws(Failure) -> Element? {
            guard let state else {
                return nil
            }

            let id = P_State.generation(state)

            do {
                if !hasStarted {
                    hasStarted = true
                } else {
                    await withTaskCancellationHandler(
                        operation: {
                            await P_State.willChange(
                                isolation: isolation,
                                state: state,
                                id: id
                            )
                        },
                        onCancel: {
                            P_State.cancel(state, id: id)
                        },
                        isolation: isolation
                    )
                }

                return try await trackEmission(
                    isolation: isolation,
                    state: state,
                    id: id
                )
            } catch {
                return try terminate(throwing: error, id: id)
            }
        }

    }

    /// An iterator over transactional observation values.
    public struct Iterator: AsyncIteratorProtocol {
        internal enum P_Backend {
            case compatibility(P_CompatibilityIterator)
            case terminal

            #if compiler(>=6.2)
            case systemElements(P_UncheckedSendableStorage)
            case systemIterations(P_UncheckedSendableStorage)
            #endif
        }

        internal var p_backend: P_Backend

        internal init(p_backend: P_Backend) {
            self.p_backend = p_backend
        }

        internal mutating func p_nextValue(
            isolation: isolated (any Actor)? = #isolation
        ) async throws(Failure) -> Element? {
            let activeBackend = p_backend
            p_backend = .terminal

            switch activeBackend {
            case .compatibility(var iterator):
                guard let value = try await iterator.nextValue(isolation: isolation) else {
                    return nil
                }

                p_backend = .compatibility(iterator)
                return value

            #if compiler(>=6.2)
            case .systemElements(let iteratorStorage):
                guard #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) else {
                    preconditionFailure("System Observations used below its availability")
                }
                var iterator = iteratorStorage.value(
                    as: Observation.Observations<Element, Failure>.Iterator.self
                )
                guard let value = try await iterator.next(isolation: isolation) else {
                    return nil
                }

                p_backend = .systemElements(P_UncheckedSendableStorage(iterator))
                return value

            case .systemIterations(let iteratorStorage):
                guard #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) else {
                    preconditionFailure("System Observations used below its availability")
                }
                var iterator = iteratorStorage.value(
                    as: Observation.Observations<Iteration, Failure>.Iterator.self
                )
                guard let iteration = try await iterator.next(isolation: isolation) else {
                    return nil
                }

                switch iteration {
                case .next(let value):
                    p_backend = .systemIterations(P_UncheckedSendableStorage(iterator))
                    return value
                case .finish:
                    return nil
                }
            #endif

            case .terminal:
                return nil
            }
        }

        /// Returns the next transactionally observed value, or `nil` after
        /// explicit completion or task cancellation.
        public mutating func next() async throws -> Element? {
            try await p_nextValue()
        }

        /// Returns the next value while preserving the caller's isolation.
        @available(iOS 18.0, macCatalyst 18.0, macOS 15.0, *)
        public mutating func next(
            isolation actor: isolated (any Actor)?
        ) async throws(Failure) -> Element? {
            try await p_nextValue(isolation: actor)
        }
    }

    public func makeAsyncIterator() -> Iterator {
        switch p_storage {
        case .compatibility(let state, let emit):
            return Iterator(
                p_backend: .compatibility(.init(state: state, emit: emit))
            )

        #if compiler(>=6.2)
        case .systemElements(let observationsStorage):
            if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                let observations = observationsStorage.value(
                    as: Observation.Observations<Element, Failure>.self
                )
                return Iterator(
                    p_backend: .systemElements(
                        P_UncheckedSendableStorage(observations.makeAsyncIterator())
                    )
                )
            } else {
                preconditionFailure("System Observations used below its availability")
            }

        case .systemIterations(let observationsStorage):
            if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                let observations = observationsStorage.value(
                    as: Observation.Observations<Iteration, Failure>.self
                )
                return Iterator(
                    p_backend: .systemIterations(
                        P_UncheckedSendableStorage(observations.makeAsyncIterator())
                    )
                )
            } else {
                preconditionFailure("System Observations used below its availability")
            }
        #endif
        }
    }
}

internal struct P_UncheckedSendableStorage: @unchecked Sendable {
    internal let storedValue: Any

    init<Value>(_ value: Value) {
        storedValue = value
    }

    func value<Value>(as _: Value.Type) -> Value {
        guard let value = storedValue as? Value else {
            preconditionFailure("Unexpected ObservationsCompat storage type")
        }

        return value
    }
}

internal final class P_CriticalState<Value>: @unchecked Sendable {
    internal let lock = NSLock()
    internal var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func withCriticalRegion<Result>(
        _ operation: (inout Value) throws -> Result
    ) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try operation(&value)
    }
}
