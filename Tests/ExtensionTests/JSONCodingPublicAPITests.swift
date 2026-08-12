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

    private struct SlowPayload: Encodable, Sendable {
        func encode(to encoder: Encoder) throws {
            Thread.sleep(forTimeInterval: 0.05)
            var container = encoder.singleValueContainer()
            try container.encode(42)
        }
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

    func testDeferredTasksCanBeStartedAndAwaitedLater() async throws {
        let coding = JSONCoding()
        let source = Payload(id: 7, displayName: "Deferred")

        let encoding = coding.encodingTask(for: source)
        let localWork = (1...100).reduce(0, +)
        let data = try await encoding.value
        let decoding = coding.decodingTask(of: Payload.self, from: data)
        let decoded = try await decoding.value

        XCTAssertEqual(localWork, 5_050)
        XCTAssertEqual(decoded, source)
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

    func testCancellingAwaitedCodingPropagatesCancellation() async {
        let task = Task {
            try await JSONCoding().encodeAsync(SlowPayload())
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        }
        catch is CancellationError {}
        catch {
            XCTFail("Expected CancellationError, received \(error)")
        }
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
}
