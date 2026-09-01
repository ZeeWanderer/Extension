//
//  ObservationsCompatPublicAPITests.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import Observation
import ObservationExtension
import XCTest

@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
@MainActor
final class ObservationsCompatPublicAPITests: XCTestCase {
    @Observable
    @MainActor
    final class Model {
        var value = 0
        var shouldThrow = false
    }

    private enum ExpectedFailure: Error, Equatable {
        case expected
    }

    private enum FailureOutcome: Equatable, Sendable {
        case expected(first: Int?, isTerminal: Bool)
        case unexpected
    }

    func testEmitsInitialValueAndCoalescesOneTransaction() async throws {
        let model = Model()
        let initialRead = expectation(description: "initial value was read")
        initialRead.assertForOverFulfill = true
        let observations = ObservationsCompat {
            let value = model.value
            if value == 0 {
                initialRead.fulfill()
            }
            return value
        }

        let consumer = Task.detached {
            var iterator = observations.makeAsyncIterator()
            var values: [Int] = []
            if let value = try await iterator.next() {
                values.append(value)
            }
            if let value = try await iterator.next() {
                values.append(value)
            }
            return values
        }

        await fulfillment(of: [initialRead], timeout: 1.0)
        model.value = 1
        model.value = 2

        let values = try await consumer.value
        XCTAssertEqual(values, [0, 2])
    }

    func testCancellationFinishesAPendingIterator() async throws {
        let model = Model()
        let initialRead = expectation(description: "initial value was read")
        let observations = ObservationsCompat<Int, Never> {
            let value = model.value
            if value == 0 {
                initialRead.fulfill()
            }
            return value
        }

        let consumer = Task.detached {
            var iterator = observations.makeAsyncIterator()
            let first = try await iterator.next()
            let second = try await iterator.next()
            return (first, second)
        }

        await fulfillment(of: [initialRead], timeout: 1.0)
        consumer.cancel()
        let values = try await consumer.value

        XCTAssertEqual(values.0, 0)
        XCTAssertNil(values.1)
    }

    func testUntilFinishedEmitsValuesThenTerminates() async throws {
        let model = Model()
        let initialRead = expectation(description: "initial value was read")
        let secondRead = expectation(description: "second value was read")
        let observations = ObservationsCompat<Int, Never>.untilFinished {
            switch model.value {
            case 0:
                initialRead.fulfill()
                return .next(0)
            case 1:
                secondRead.fulfill()
                return .next(1)
            default:
                return .finish
            }
        }

        let consumer = Task.detached {
            var values: [Int] = []
            for try await value in observations {
                values.append(value)
            }
            return values
        }

        await fulfillment(of: [initialRead], timeout: 1.0)
        model.value = 1
        await fulfillment(of: [secondRead], timeout: 1.0)
        model.value = 2

        let values = try await consumer.value
        XCTAssertEqual(values, [0, 1])
    }

    func testUntilFinishedRemainsTerminalAfterFinish() async throws {
        let observations = ObservationsCompat<Int, Never>.untilFinished {
            .finish
        }
        var iterator = observations.makeAsyncIterator()

        let first = try await iterator.next()
        let second = try await iterator.next()

        XCTAssertNil(first)
        XCTAssertNil(second)
    }

    func testThrownFailureTerminatesIterator() async throws {
        let model = Model()
        let initialRead = expectation(description: "initial value was read")
        let observations = ObservationsCompat<Int, ExpectedFailure> { () throws(ExpectedFailure) -> Int in
            if model.shouldThrow {
                throw ExpectedFailure.expected
            }

            initialRead.fulfill()
            return model.value
        }

        let consumer = Task.detached {
            var iterator = observations.makeAsyncIterator()
            let first = try await iterator.next()

            do {
                _ = try await iterator.next()
                return FailureOutcome.unexpected
            } catch ExpectedFailure.expected {
                let terminalValue = try? await iterator.next()
                return .expected(first: first, isTerminal: terminalValue == nil)
            } catch {
                return .unexpected
            }
        }

        await fulfillment(of: [initialRead], timeout: 1.0)
        model.shouldThrow = true

        let outcome = try await consumer.value
        XCTAssertEqual(outcome, FailureOutcome.expected(first: 0, isTerminal: true))
    }

    func testSharedSequenceWakesIndependentIterators() async throws {
        let model = Model()
        let initialReads = expectation(description: "both iterators read the initial value")
        initialReads.expectedFulfillmentCount = 2
        let observations = ObservationsCompat<Int, Never> {
            let value = model.value
            if value == 0 {
                initialReads.fulfill()
            }
            return value
        }

        func consumeTwoValues() async throws -> [Int] {
            var iterator = observations.makeAsyncIterator()
            return [
                try await iterator.next(),
                try await iterator.next(),
            ].compactMap { $0 }
        }

        let firstConsumer = Task.detached {
            try await consumeTwoValues()
        }
        let secondConsumer = Task.detached {
            try await consumeTwoValues()
        }

        await fulfillment(of: [initialReads], timeout: 1.0)
        model.value = 5

        let firstValues = try await firstConsumer.value
        let secondValues = try await secondConsumer.value
        XCTAssertEqual(firstValues, [0, 5])
        XCTAssertEqual(secondValues, [0, 5])
    }

    func testBasicTransactionMatchesSystemObservationsWhenAvailable() async throws {
        guard #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) else {
            throw XCTSkip("System Observations is unavailable on this platform")
        }

        let compatModel = Model()
        let systemModel = Model()
        let compat = ObservationsCompat<Int, Never> {
            compatModel.value
        }
        let system = Observation.Observations<Int, Never> {
            systemModel.value
        }
        var compatIterator = compat.makeAsyncIterator()
        var systemIterator = system.makeAsyncIterator()

        let compatInitial = await compatIterator.next(isolation: #isolation)
        let systemInitial = await systemIterator.next(isolation: #isolation)
        let compatChange = Task { @MainActor [compatIterator] in
            var iterator = compatIterator
            return await iterator.next(isolation: #isolation)
        }
        let systemChange = Task { @MainActor [systemIterator] in
            var iterator = systemIterator
            return await iterator.next(isolation: #isolation)
        }

        compatModel.value = 3
        compatModel.value = 4
        systemModel.value = 3
        systemModel.value = 4

        let compatValues = [compatInitial, await compatChange.value]
        let systemValues = [systemInitial, await systemChange.value]
        XCTAssertEqual(compatValues, systemValues)
        XCTAssertEqual(compatValues, [0, 4])
    }
}
