//
//  JSONCodingPublicAPITests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

final class JSONCodingPublicAPITests: XCTestCase {
    private static let threadRecorderKey = CodingUserInfoKey(
        rawValue: "JSONCodingPublicAPITests.threadRecorder"
    )!

    private struct Payload: Codable, Equatable, Sendable {
        let id: Int
        let displayName: String
    }

    private enum DictionaryKey: String, Codable, Sendable {
        case primary
        case secondary
    }

    private enum TaskContext {
        @TaskLocal static var marker: String?
    }

    private struct TaskContextPayload: Encodable, Sendable {
        let expectedMarker: String?

        func encode(to encoder: Encoder) throws {
            guard TaskContext.marker == expectedMarker else {
                throw TaskContextError.unexpectedMarker
            }

            var container = encoder.singleValueContainer()
            try container.encode(42)
        }
    }

    private enum TaskContextError: Error {
        case unexpectedMarker
    }

    private final class ThreadRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var recordedValue: Bool?

        func record(isMainThread: Bool) {
            lock.lock()
            recordedValue = isMainThread
            lock.unlock()
        }

        var wasMainThread: Bool? {
            lock.lock()
            defer { lock.unlock() }
            return recordedValue
        }
    }

    private struct ThreadRecordingPayload: Encodable, Sendable {
        let recorder: ThreadRecorder

        func encode(to encoder: Encoder) throws {
            recorder.record(isMainThread: Thread.isMainThread)
            var container = encoder.singleValueContainer()
            try container.encode(42)
        }
    }

    private struct ThreadRecordingDecodedValue: Decodable, Sendable {
        init(from decoder: Decoder) throws {
            let recorder = decoder.userInfo[JSONCodingPublicAPITests.threadRecorderKey]
                as? ThreadRecorder
            recorder?.record(isMainThread: Thread.isMainThread)
            _ = try decoder.singleValueContainer().decode(Int.self)
        }
    }

    private struct GatedPayload: Encodable, Sendable {
        let gate: EncodingGate

        func encode(to encoder: Encoder) throws {
            gate.blockUntilReleased()
            var container = encoder.singleValueContainer()
            try container.encode(42)
        }
    }

    private final class EncodingGate: @unchecked Sendable {
        private let condition = NSCondition()
        private var started = false
        private var released = false

        var hasStarted: Bool {
            condition.lock()
            defer { condition.unlock() }
            return started
        }

        func blockUntilReleased() {
            condition.lock()
            started = true
            condition.broadcast()
            while !released {
                condition.wait()
            }
            condition.unlock()
        }

        func release() {
            condition.lock()
            released = true
            condition.broadcast()
            condition.unlock()
        }
    }

    private enum AsyncOutcome: Equatable, Sendable {
        case success
        case cancellation
        case failure(String)
    }

    func testSynchronousCodingRoundTripsAndUsesConfiguredCoders() throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let coding = JSONCoding(encoder: encoder, decoder: decoder)
        let source = Payload(id: 42, displayName: "Configured")

        let data = try coding.encode(source)
        let decoded = try coding.decode(Payload.self, from: data)

        XCTAssertEqual(String(decoding: data, as: UTF8.self), #"{"display_name":"Configured","id":42}"#)
        XCTAssertEqual(decoded, source)
    }

    func testGeneralCodingPreservesFoundationDictionaryRoundTrips() throws {
        let source: [DictionaryKey: Int] = [.primary: 1, .secondary: 2]
        let coding = JSONCoding()

        let data = try coding.encode(source)
        let decoded = try coding.decode([DictionaryKey: Int].self, from: data)

        XCTAssertEqual(decoded, source)
    }

    func testExplicitTasksCanBeStartedAndAwaitedLater() async throws {
        let coding = JSONCoding()
        let source = Payload(id: 7, displayName: "Deferred")

        let encoding = coding.detachedEncodingTask(for: source)
        let localWork = (1...100).reduce(0, +)
        let data = try await encoding.value
        let decoding = coding.detachedDecodingTask(of: Payload.self, from: data)
        let decoded = try await decoding.value

        XCTAssertEqual(localWork, 5_050)
        XCTAssertEqual(decoded, source)
    }

    func testExplicitTaskCodingIsDetachedFromTaskLocalContext() async throws {
        try await TaskContext.$marker.withValue("parent-context") {
            _ = try await JSONCoding().detachedEncodingTask(
                for: TaskContextPayload(expectedMarker: nil)
            ).value
        }
    }

    func testExplicitFileAndResourceTasks() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Extension-JSONCoding-task-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let coding = JSONCoding()
        let source = Payload(id: 11, displayName: "Explicit task")

        try await coding.detachedEncodingTask(
            for: source,
            to: fileURL,
            options: [.atomic],
            priority: .utility
        ).value
        let decoded = try await coding.detachedDecodingTask(
            of: Payload.self,
            contentsOf: fileURL,
            options: [.mappedIfSafe],
            priority: .utility
        ).value
        let resource = try await coding.detachedDecodingTask(
            of: Payload.self,
            fromResource: "JSONCodingPayload",
            in: .module,
            priority: .utility
        ).value

        XCTAssertEqual(decoded, source)
        XCTAssertEqual(resource, Payload(id: 42, displayName: "Bundled value"))

        do {
            _ = try await coding.detachedDecodingTask(
                of: Payload.self,
                fromResource: "MissingJSONCodingPayload",
                in: .module
            ).value
            XCTFail("Expected the missing-resource error")
        }
        catch {
            XCTAssertEqual(
                error as? JSONCodingError,
                .resourceNotFound(
                    name: "MissingJSONCodingPayload",
                    fileExtension: "json",
                    subdirectory: nil
                )
            )
        }
    }

    func testCancellingAnExplicitEncodingTaskPropagatesCancellation() async {
        let gate = EncodingGate()
        let task = JSONCoding().detachedEncodingTask(for: GatedPayload(gate: gate))

        while !gate.hasStarted {
            await Task.yield()
        }

        task.cancel()
        gate.release()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        }
        catch is CancellationError {}
        catch {
            XCTFail("Expected CancellationError, received \(error)")
        }
    }

    func testStructuredConcurrentCodingRoundTrips() async throws {
        let coding = JSONCoding()
        let first = Payload(id: 1, displayName: "First")
        let second = Payload(id: 2, displayName: "Second")

        async let firstData = coding.encodeAsync(first)
        async let secondData = coding.encodeAsync(second)
        let encoded = try await (firstData, secondData)
        async let firstCopy = coding.decodeAsync(Payload.self, from: encoded.0)
        async let secondCopy = coding.decodeAsync(Payload.self, from: encoded.1)

        let decoded = try await (firstCopy, secondCopy)
        XCTAssertEqual(decoded.0, first)
        XCTAssertEqual(decoded.1, second)
    }

    func testAsyncCodingPreservesStructuredTaskLocalContext() async throws {
        try await TaskContext.$marker.withValue("structured-context") {
            _ = try await JSONCoding().encodeAsync(
                TaskContextPayload(expectedMarker: "structured-context")
            )
        }
    }

    @MainActor
    func testAwaitedAsyncCodingDoesNotEncodeOnTheMainThread() async throws {
        let recorder = ThreadRecorder()

        _ = try await JSONCoding().encodeAsync(ThreadRecordingPayload(recorder: recorder))

        XCTAssertEqual(recorder.wasMainThread, false)
    }

    @MainActor
    func testAwaitedAsyncCodingDoesNotDecodeOnTheMainThread() async throws {
        let recorder = ThreadRecorder()
        let decoder = JSONDecoder()
        decoder.userInfo[Self.threadRecorderKey] = recorder
        let coding = JSONCoding(decoder: decoder)

        _ = try await coding.decodeAsync(
            ThreadRecordingDecodedValue.self,
            from: Data("42".utf8)
        )

        XCTAssertEqual(recorder.wasMainThread, false)
    }

    func testAwaitedAsyncCodingRoundTrips() async throws {
        let source = Payload(id: 8, displayName: "Async")
        let coding = JSONCoding()

        let data = try await coding.encodeAsync(source)
        let decoded = try await coding.decodeAsync(Payload.self, from: data)

        XCTAssertEqual(decoded, source)
    }

    func testCancellingCodingDuringFoundationEncodingPropagatesCancellation() async {
        let gate = EncodingGate()

        await withTaskGroup(of: AsyncOutcome.self) { group in
            group.addTask {
                do {
                    _ = try await JSONCoding().encodeAsync(GatedPayload(gate: gate))
                    return .success
                }
                catch is CancellationError {
                    return .cancellation
                }
                catch {
                    return .failure(String(describing: error))
                }
            }

            while !gate.hasStarted {
                await Task.yield()
            }

            group.cancelAll()
            gate.release()

            let outcome = await group.next()
            XCTAssertEqual(outcome, .cancellation)
        }
    }

    func testCancellationBeforeAFileWriteLeavesNoFile() async {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Extension-JSONCoding-cancelled-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let gate = EncodingGate()

        await withTaskGroup(of: AsyncOutcome.self) { group in
            group.addTask {
                do {
                    try await JSONCoding().encodeAsync(GatedPayload(gate: gate), to: fileURL)
                    return .success
                }
                catch is CancellationError {
                    return .cancellation
                }
                catch {
                    return .failure(String(describing: error))
                }
            }

            while !gate.hasStarted {
                await Task.yield()
            }

            group.cancelAll()
            gate.release()

            let outcome = await group.next()
            XCTAssertEqual(outcome, .cancellation)
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testSynchronousAndAsynchronousFileCoding() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Extension-JSONCoding-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let coding = JSONCoding()
        let synchronous = Payload(id: 9, displayName: "File")

        try coding.encode(synchronous, to: fileURL)
        let synchronouslyDecoded = try coding.decode(Payload.self, contentsOf: fileURL)
        XCTAssertEqual(synchronouslyDecoded, synchronous)

        let asynchronous = Payload(id: 10, displayName: "Async file")
        try await coding.encodeAsync(asynchronous, to: fileURL)
        let asynchronouslyDecoded = try await coding.decodeAsync(
            Payload.self,
            contentsOf: fileURL
        )
        XCTAssertEqual(asynchronouslyDecoded, asynchronous)
    }

    func testBundledResourceCodingAndMissingResourceErrors() throws {
        let coding = JSONCoding()

        let payload = try coding.decode(
            Payload.self,
            fromResource: "JSONCodingPayload",
            in: .module
        )

        XCTAssertEqual(payload, Payload(id: 42, displayName: "Bundled value"))
        XCTAssertThrowsError(
            try coding.decode(
                Payload.self,
                fromResource: "MissingJSONCodingPayload",
                in: .module
            )
        ) { error in
            XCTAssertEqual(
                error as? JSONCodingError,
                .resourceNotFound(
                    name: "MissingJSONCodingPayload",
                    fileExtension: "json",
                    subdirectory: nil
                )
            )
        }
    }

    func testAsynchronousBundledResourceCodingAndMissingResourceErrors() async throws {
        let coding = JSONCoding()

        let payload = try await coding.decodeAsync(
            Payload.self,
            fromResource: "JSONCodingPayload",
            in: .module
        )

        XCTAssertEqual(payload, Payload(id: 42, displayName: "Bundled value"))

        do {
            _ = try await coding.decodeAsync(
                Payload.self,
                fromResource: "MissingJSONCodingPayload",
                in: .module
            )
            XCTFail("Expected the missing-resource error")
        }
        catch {
            XCTAssertEqual(
                error as? JSONCodingError,
                .resourceNotFound(
                    name: "MissingJSONCodingPayload",
                    fileExtension: "json",
                    subdirectory: nil
                )
            )
        }
    }

    func testMalformedDataAndMissingFilesPropagateErrors() async {
        let coding = JSONCoding()
        let malformedData = Data(#"{"id":"wrong type"}"#.utf8)
        let missingFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Extension-JSONCoding-missing-\(UUID().uuidString).json")

        XCTAssertThrowsError(try coding.decode(Payload.self, from: malformedData))
        XCTAssertThrowsError(try coding.decode(Payload.self, contentsOf: missingFileURL))

        do {
            _ = try await coding.decodeAsync(Payload.self, from: malformedData)
            XCTFail("Expected malformed JSON to fail")
        }
        catch is DecodingError {}
        catch {
            XCTFail("Expected DecodingError, received \(error)")
        }

        do {
            _ = try await coding.decodeAsync(Payload.self, contentsOf: missingFileURL)
            XCTFail("Expected the missing file to fail")
        }
        catch {
            XCTAssertTrue((error as NSError).domain == NSCocoaErrorDomain)
        }
    }

    func testConcurrentUseOfConfiguredCoders() async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let coding = JSONCoding(encoder: encoder, decoder: decoder)
        let count = 256

        let decoded = try await withThrowingTaskGroup(of: Payload.self) { group in
            for id in 0..<count {
                group.addTask {
                    let source = Payload(id: id, displayName: "Value \(id)")
                    let data = try await coding.encodeAsync(source)
                    return try await coding.decodeAsync(Payload.self, from: data)
                }
            }

            var values: [Payload] = []
            values.reserveCapacity(count)
            for try await value in group {
                values.append(value)
            }
            return values
        }

        XCTAssertEqual(decoded.map(\.id).sorted(), Array(0..<count))
    }
}
