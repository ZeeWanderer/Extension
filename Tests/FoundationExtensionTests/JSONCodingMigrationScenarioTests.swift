//
//  JSONCodingMigrationScenarioTests.swift
//
//
//  Created by zeewanderer on 04.09.2026.
//

import Foundation
import FoundationExtension
import XCTest

final class JSONCodingMigrationScenarioTests: XCTestCase
{
    // Fixtures contain representative real-world coding shapes with identifying details removed.

    enum P_TaskCategory: String, Codable, CaseIterable, Sendable
    {
        case younger = "3-6"
        case older = "5-8"
    }

    enum P_TaskType: String, Codable, CaseIterable, Sendable
    {
        case twoSlots = "_2slots"
        case twoSlotPairs = "_2slots_pairs"
        case digitAnswer = "digit_answer"
        case extendRow = "extend_row"
        case extendRowNine = "extend_row_9"
        case missingPictureFive = "missing_picture_5"
        case oneFromTwo = "one_from_2"
        case oneFromTwoOrMoreImages = "one_from_2or_more_images"
        case oneFromThree = "one_from_3"
        case patternMatchingImages = "pattern_matching_images"
        case threeFromTen = "three_from_10"
        case trueFalseImages = "true_false_images"
    }

    enum P_TaskTheme: String, Decodable, Sendable
    {
        case math
        case logic
        case datetime
        case terms
        case facts
    }

    enum P_TaskDetails: Equatable, Sendable
    {
        case indexedAnswers(
            answerCount: Int,
            answerIndex: Int,
            slotCount: Int?,
            imageName: String?
        )
        case multipleAnswers(answerCount: Int, answerIndices: [Int], slotCount: Int?)
        case digitAnswer(correct: Int, answerUnit: String, imageName: String)
        case missingPicture(answerCount: Int, imageCount: Int, missingIndex: Int)
        case trueFalse(answer: Bool, imageName: String)
    }

    struct P_Task: Decodable, Equatable, Sendable
    {
        let id: String
        let type: P_TaskType
        let category: P_TaskCategory
        let theme: P_TaskTheme
        let question: String
        let details: P_TaskDetails

        enum CodingKeys: String, CodingKey
        {
            case id
            case type
            case category
            case theme
            case question
            case answers
            case answerIndex = "answer_idx"
            case slots
            case correct
            case answerUnit = "answer_unit"
            case imageName = "image_name"
            case images
            case missingIndex = "missing_idx"
            case answer
        }

        init(from decoder: Decoder) throws
        {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            type = try container.decode(P_TaskType.self, forKey: .type)
            category = try container.decode(P_TaskCategory.self, forKey: .category)
            theme = try container.decode(P_TaskTheme.self, forKey: .theme)
            question = try container.decode(String.self, forKey: .question)

            switch type
            {
                case .twoSlots, .twoSlotPairs:
                    details = try .multipleAnswers(
                        answerCount: container.decode([String].self, forKey: .answers).count,
                        answerIndices: container.decode([Int].self, forKey: .answerIndex),
                        slotCount: container.decode([String].self, forKey: .slots).count
                    )
                case .threeFromTen:
                    details = try .multipleAnswers(
                        answerCount: container.decode([String].self, forKey: .answers).count,
                        answerIndices: container.decode([Int].self, forKey: .answerIndex),
                        slotCount: nil
                    )
                case .digitAnswer:
                    details = try .digitAnswer(
                        correct: container.decode(Int.self, forKey: .correct),
                        answerUnit: container.decode(String.self, forKey: .answerUnit),
                        imageName: container.decode(String.self, forKey: .imageName)
                    )
                case .missingPictureFive:
                    details = try .missingPicture(
                        answerCount: container.decode([String].self, forKey: .answers).count,
                        imageCount: container.decode([String].self, forKey: .images).count,
                        missingIndex: container.decode(Int.self, forKey: .missingIndex)
                    )
                case .trueFalseImages:
                    details = try .trueFalse(
                        answer: container.decode(Bool.self, forKey: .answer),
                        imageName: container.decode(String.self, forKey: .imageName)
                    )
                case .extendRow, .extendRowNine, .oneFromTwo,
                     .oneFromTwoOrMoreImages, .oneFromThree, .patternMatchingImages:
                    details = try .indexedAnswers(
                        answerCount: container.decode([String].self, forKey: .answers).count,
                        answerIndex: container.decode(Int.self, forKey: .answerIndex),
                        slotCount: container.decodeIfPresent([String].self, forKey: .slots)?.count,
                        imageName: container.decodeIfPresent(String.self, forKey: .imageName)
                    )
            }
        }
    }

    struct P_TaskDatabase: Decodable, Sendable
    {
        let tasks: [String: P_Task]

        init(from decoder: Decoder) throws
        {
            let container = try decoder.container(keyedBy: P_AnyCodingKey.self)
            var tasks = [String: P_Task]()
            tasks.reserveCapacity(container.allKeys.count)

            for key in container.allKeys
            {
                let discriminator = try container.nestedContainer(
                    keyedBy: P_TaskCodingKey.self,
                    forKey: key
                )
                let type = try discriminator.decode(P_TaskType.self, forKey: .type)
                let task = try container.decode(P_Task.self, forKey: key)

                guard type == task.type, key.stringValue == task.id else
                {
                    throw DecodingError.dataCorruptedError(
                        forKey: key,
                        in: container,
                        debugDescription: "The task dictionary key and discriminator must match the task"
                    )
                }

                tasks[key.stringValue] = task
            }

            self.tasks = tasks
        }
    }

    enum P_TaskCodingKey: CodingKey
    {
        case type
    }

    struct P_AnyCodingKey: CodingKey
    {
        let stringValue: String
        let intValue: Int?

        init?(stringValue: String)
        {
            self.stringValue = stringValue
            intValue = nil
        }

        init?(intValue: Int)
        {
            stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    struct P_LevelLandscapeData: Decodable, Equatable, Sendable
    {
        enum P_LevelType: String, Decodable, Sendable
        {
            case levelBackground = "level_background"
            case story
        }

        let type: P_LevelType
        let name: String
        let road: String
        let reversed: Bool
        let decorators: [String]
    }

    struct P_Point: Codable, Hashable, Sendable
    {
        let y: Int
        let x: Int
        let name: String?
    }

    enum P_FixtureColor: String, Codable, Sendable
    {
        case red
        case green
        case blue
        case yellow
        case violet
        case fuchsia
        case orange
        case lightgreen
    }

    struct P_Line: Codable, Hashable, Sendable
    {
        let start: P_Point
        let end: P_Point
        let color: P_FixtureColor
    }

    struct P_Figurine: Codable, Hashable, Sendable
    {
        let id: String
        let lines: [P_Line]
        let title: String
        let name: [String: String]
        let colored: Bool
    }

    struct P_SingleLineGraph: Codable, Equatable, Sendable
    {
        let id: String
        let areaSize: Int
        let level: Int
        let title: String
        let vertices: [P_Point]
        let edges: [Set<Int>]

        enum CodingKeys: String, CodingKey
        {
            case id
            case areaSize = "area_size"
            case level
            case title
            case vertices
            case edges
        }
    }

    struct P_RequestLogEntry: Codable, Equatable, Sendable
    {
        let timestamp: String
        let url: String?
        let statusCode: Int?
        let parameters: [String: String]?
        let body: String?
        let response: String?
        let error: String?
        let message: String?
        let object: String?
    }

    struct P_DatedResponse: Decodable, Equatable, Sendable
    {
        let createdAt: Date
    }

    func testRawRepresentableDictionariesDecodeThroughJSONCoding() async throws
    {
        let coding = JSONCoding()

        let categories = try coding.decode(
            [P_TaskCategory: [String]].self,
            fromResource: "RawKeyCategoryDictionary",
            in: .module
        )
        let types = try await coding.detachedDecodingTask(
            of: [P_TaskType: [String]].self,
            fromResource: "RawKeyTypeDictionary",
            in: .module
        ).value

        XCTAssertEqual(categories[.younger]?.count, 3)
        XCTAssertEqual(categories[.older]?.count, 2)
        XCTAssertEqual(categories[.younger]?.first, "one_from_two_sample")
        XCTAssertEqual(categories[.older]?.last, "pattern_matching_sample")
        XCTAssertEqual(types.count, P_TaskType.allCases.count)
        XCTAssertEqual(types.values.reduce(0) { $0 + $1.count }, P_TaskType.allCases.count)
        XCTAssertEqual(types[.digitAnswer], ["digit_answer_sample"])
        XCTAssertEqual(types[.trueFalseImages], ["true_false_sample"])
    }

    func testTrailingCommaResourceDecodesThroughJSONCoding() async throws
    {
        let levels = try await JSONCoding().decodeAsync(
            [P_TaskCategory: [P_LevelLandscapeData]].self,
            fromResource: "TrailingCommaLevels",
            in: .module
        )

        XCTAssertEqual(levels[.younger]?.count, 1)
        XCTAssertEqual(levels[.older]?.count, 1)
        XCTAssertEqual(levels[.younger]?.first?.name, "level_0")
        XCTAssertEqual(levels[.older]?.first?.name, "level_0_5-8")
        XCTAssertTrue(levels.values.flatMap { $0 }.allSatisfy { $0.type == .levelBackground })
    }

    func testDynamicTaskDatabaseDecodesEveryTaskDiscriminatorAndPayloadShape() async throws
    {
        let database = try await JSONCoding().decodeAsync(
            P_TaskDatabase.self,
            fromResource: "DiscriminatedTaskDatabase",
            in: .module
        )
        let counts = Dictionary(grouping: database.tasks.values, by: \.type)
            .mapValues(\.count)

        XCTAssertEqual(database.tasks.count, P_TaskType.allCases.count)
        XCTAssertEqual(counts.count, P_TaskType.allCases.count)
        XCTAssertTrue(counts.values.allSatisfy { $0 == 1 })
        XCTAssertEqual(database.tasks["one_from_two_sample"]?.type, .oneFromTwo)
        XCTAssertEqual(database.tasks["pattern_matching_sample"]?.type, .patternMatchingImages)
        XCTAssertEqual(
            database.tasks["two_slots_sample"]?.details,
            .multipleAnswers(answerCount: 3, answerIndices: [2, 1], slotCount: 2)
        )
        XCTAssertEqual(
            database.tasks["extend_row_nine_sample"]?.details,
            .indexedAnswers(answerCount: 3, answerIndex: 2, slotCount: 9, imageName: nil)
        )
        XCTAssertEqual(
            database.tasks["digit_answer_sample"]?.details,
            .digitAnswer(
                correct: 0,
                answerUnit: "items",
                imageName: "image/fruit_tree"
            )
        )
        XCTAssertEqual(
            database.tasks["missing_picture_sample"]?.details,
            .missingPicture(answerCount: 3, imageCount: 5, missingIndex: 3)
        )
        XCTAssertEqual(
            database.tasks["true_false_sample"]?.details,
            .trueFalse(answer: false, imageName: "image/pet_food")
        )
    }

    func testStructuredStartupDecodePreservesNumericKeysAndSets() async throws
    {
        let coding = JSONCoding()

        async let figurines = coding.decodeAsync(
            [Int: [P_Figurine]].self,
            fromResource: "NumericKeyFigurines",
            in: .module
        )
        async let singleLineGraphs = coding.decodeAsync(
            [P_SingleLineGraph].self,
            fromResource: "NestedSetGraphs",
            in: .module
        )

        let decodedFigurines = try await figurines
        let decodedSingleLineGraphs = try await singleLineGraphs

        XCTAssertEqual(decodedFigurines.keys.sorted(), [3, 10])
        XCTAssertEqual(decodedFigurines.values.flatMap { $0 }.count, 2)
        XCTAssertEqual(decodedFigurines[3]?.first?.id, "small_shape")
        XCTAssertEqual(decodedFigurines[10]?.first?.id, "large_shape")
        XCTAssertEqual(decodedSingleLineGraphs.count, 2)
        XCTAssertEqual(decodedSingleLineGraphs.first?.id, "graph_1")
        XCTAssertEqual(decodedSingleLineGraphs.first?.edges.first, Set([0, 1]))
        XCTAssertTrue(decodedSingleLineGraphs.flatMap(\.vertices).allSatisfy { $0.name == nil })

        let figurineData = try coding.encode(decodedFigurines)
        let graphData = try coding.encode(decodedSingleLineGraphs)
        XCTAssertEqual(
            try coding.decode([Int: [P_Figurine]].self, from: figurineData),
            decodedFigurines
        )
        XCTAssertEqual(
            try coding.decode([P_SingleLineGraph].self, from: graphData),
            decodedSingleLineGraphs
        )
    }

    func testLogFileCanBeReadAppendedAndAtomicallyRewritten() throws
    {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Extension-JSONCoding-log-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let coding = JSONCoding()
        let first = P_RequestLogEntry(
            timestamp: "2026-09-04T08:00:00Z",
            url: nil,
            statusCode: nil,
            parameters: nil,
            body: nil,
            response: nil,
            error: nil,
            message: "Sync started",
            object: nil
        )
        let second = P_RequestLogEntry(
            timestamp: "2026-09-04T08:00:01Z",
            url: "https://example.com/api",
            statusCode: 200,
            parameters: ["page": "1"],
            body: #"{"id":42}"#,
            response: #"{"success":true}"#,
            error: nil,
            message: nil,
            object: nil
        )

        try coding.encode([first], to: fileURL)
        var entries = try coding.decode([P_RequestLogEntry].self, contentsOf: fileURL)
        entries.append(second)
        try coding.encode(entries, to: fileURL, options: [.atomic])

        XCTAssertEqual(
            try coding.decode([P_RequestLogEntry].self, contentsOf: fileURL),
            [first, second]
        )
    }

    func testConfiguredProjectDateDecoderIsUsedForAsyncDecoding() async throws
    {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        let data = Data(#"{"createdAt":"2026-09-04T12:34:56.789Z"}"#.utf8)

        let response = try await JSONCoding(decoder: decoder).decodeAsync(
            P_DatedResponse.self,
            from: data
        )

        XCTAssertEqual(response.createdAt, formatter.date(from: "2026-09-04T12:34:56.789Z"))
    }
}
