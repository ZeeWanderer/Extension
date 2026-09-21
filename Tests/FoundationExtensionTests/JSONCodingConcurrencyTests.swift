//
//  JSONCodingConcurrencyTests.swift
//
//
//  Created by zeewanderer on 10.09.2026.
//

import Foundation
import FoundationExtension
import XCTest

final class JSONCodingConcurrencyTests: XCTestCase
{
    static let p_recorderKey = CodingUserInfoKey(rawValue: "contextRecorder")!

    struct P_Probe: Codable, Sendable
    {
        init() {}

        init(from decoder: Decoder) throws
        {
            (decoder.userInfo[p_recorderKey] as? P_ConcurrencyContext.Recorder)?.record("decode")
        }

        func encode(to encoder: Encoder) throws
        {
            (encoder.userInfo[p_recorderKey] as? P_ConcurrencyContext.Recorder)?.record("encode")
            var container = encoder.singleValueContainer()
            try container.encode(42)
        }
    }

    enum P_Key: String, Codable, Sendable
    {
        case younger = "3-6"
        case older = "5-8"
    }

    @MainActor
    func testEveryAsyncCodingEntryPointLeavesTheActorWithoutCreatingAnotherTask() async throws
    {
        let recorder = P_ConcurrencyContext.Recorder()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        encoder.userInfo[Self.p_recorderKey] = recorder
        decoder.userInfo[Self.p_recorderKey] = recorder
        let coding = JSONCoding(encoder: encoder, decoder: decoder)
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("Extension-JSON-context-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let taskID = try XCTUnwrap(withUnsafeCurrentTask { $0?.hashValue })

        try await P_ConcurrencyContext.$marker.withValue("json-caller") {
            let data = try await coding.encodeAsync(P_Probe())
            _ = try await coding.decodeAsync(P_Probe.self, from: data)
            try await coding.encodeAsync(P_Probe(), to: file)
            _ = try await coding.decodeAsync(P_Probe.self, contentsOf: file)
            _ = try await coding.decodeAsync(P_Probe.self, fromResource: "JSONCodingPayload", in: .module)

            let dictionaryData = Data(#"{"3-6":[42]}"#.utf8)
            try dictionaryData.write(to: file)
            _ = try await coding.decodeAsync([P_Key: [P_Probe]].self, from: dictionaryData)
            _ = try await coding.decodeAsync([P_Key: [P_Probe]].self, contentsOf: file)
            _ = try await coding.decodeAsync([P_Key: [P_Probe]].self, fromResource: "RawKeyCategoryDictionary", in: .module)
        }

        XCTAssertEqual(recorder.snapshots.count, 12)
        for snapshot in recorder.snapshots
        {
            XCTAssertFalse(snapshot.isMainThread, snapshot.operation)
            XCTAssertEqual(snapshot.taskID, taskID, snapshot.operation)
            XCTAssertEqual(snapshot.marker, "json-caller", snapshot.operation)
        }
        MainActor.assertIsolated()
    }

    struct P_CancellingValue: Decodable, Sendable
    {
        init(from decoder: Decoder) throws
        {
            withUnsafeCurrentTask { $0?.cancel() }
        }
    }

    func testCancellationDuringDecodingCancelsTheCallingChildTask() async
    {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                do
                {
                    _ = try await JSONCoding().decodeAsync(P_CancellingValue.self, from: Data("42".utf8))
                    return false
                }
                catch is CancellationError { return Task.isCancelled }
                catch { return false }
            }
            let wasCancelled = await group.next()
            XCTAssertEqual(wasCancelled, true)
        }
    }
}
