//
//  LossyTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation
import XCTest
@testable import FoundationExtension

final class LossyTests: XCTestCase
{
    final class TestLossyReporter: LossyDecodingReporter, @unchecked Sendable
    {
        struct Record
        {
            let raw: String?
            let codingPath: [CodingKey]
            let message: String
            let underlying: Error?
        }
        
        private let lock = NSLock()
        private(set) var records: [Record] = []
        
        func recordLoss(raw: String?, codingPath: [CodingKey], message: String, underlying: Error?)
        {
            lock.lock()
            records.append(.init(raw: raw, codingPath: codingPath, message: message, underlying: underlying))
            lock.unlock()
        }
    }
    
    func testLossyArrayDropsInvalidElements() throws
    {
        struct Payload: Decodable
        {
            @Lossy var values: [Int]
        }
        
        let decoder = JSONDecoder()
        let reporter = TestLossyReporter()
        decoder.setLossyReporter(reporter)
        
        let data = #"{"values":[1,"bad",2]}"#.data(using: .utf8)!
        let decoded = try decoder.decode(Payload.self, from: data)
        
        XCTAssertEqual(decoded.values, [1, 2])
        XCTAssertEqual(reporter.records.count, 1)
        XCTAssertEqual(reporter.records.first?.message, "Dropped invalid array element at Index 1")
    }
    
    func testLossyOptionalBecomesNilOnInvalidValue() throws
    {
        struct Payload: Decodable
        {
            @Lossy var value: Int?
        }
        
        let decoder = JSONDecoder()
        let reporter = TestLossyReporter()
        decoder.setLossyReporter(reporter)
        
        let data = #"{"value":"bad"}"#.data(using: .utf8)!
        let decoded = try decoder.decode(Payload.self, from: data)
        
        XCTAssertNil(decoded.value)
        XCTAssertEqual(reporter.records.count, 1)
        XCTAssertEqual(reporter.records.first?.message, "Set optional to nil due to invalid value")
    }
    
    func testLossyStandardDecoding() throws
    {
        struct Payload: Decodable
        {
            @Lossy var count: Int
            @Lossy var name: String
            @Lossy var url: URL
            @Lossy var values: [Int]
            @Lossy var optionalValues: [Int]?
            @Lossy var optionalURL: URL?
        }
        
        let data = """
        {
          "count": 3,
          "name": "Alpha",
          "url": "https://example.com",
          "values": [1, 2, 3],
          "optionalValues": [4, 5],
          "optionalURL": "https://example.com/optional"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let reporter = TestLossyReporter()
        decoder.setLossyReporter(reporter)
        
        let decoded = try decoder.decode(Payload.self, from: data)
        
        XCTAssertEqual(decoded.count, 3)
        XCTAssertEqual(decoded.name, "Alpha")
        XCTAssertEqual(decoded.url, URL(string: "https://example.com"))
        XCTAssertEqual(decoded.values, [1, 2, 3])
        XCTAssertEqual(decoded.optionalValues, [4, 5])
        XCTAssertEqual(decoded.optionalURL, URL(string: "https://example.com/optional"))
        XCTAssertEqual(reporter.records.count, 0)
    }
    
    func testLossyRequiredThrowsAndReports() throws
    {
        struct Payload: Decodable
        {
            @Lossy var value: Int
        }
        
        let decoder = JSONDecoder()
        let reporter = TestLossyReporter()
        decoder.setLossyReporter(reporter)
        
        let data = #"{"value":"bad"}"#.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(Payload.self, from: data))
        XCTAssertEqual(reporter.records.count, 1)
        XCTAssertEqual(reporter.records.first?.message, "Failed to decode required value")
    }
    
    func testLossyRequiredMissingKeyThrows() throws
    {
        struct Payload: Decodable
        {
            @Lossy var value: Int
        }
        
        let decoder = JSONDecoder()
        decoder.setLossyReporter(TestLossyReporter())
        let data = #"{}"#.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(Payload.self, from: data))
    }
    
    func testLossyOptionalURLInvalidBecomesNil() throws
    {
        struct Payload: Decodable
        {
            @Lossy var url: URL?
        }
        
        let data = #"{"url":123}"#.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let reporter = TestLossyReporter()
        decoder.setLossyReporter(reporter)
        
        let decoded = try decoder.decode(Payload.self, from: data)
        
        XCTAssertNil(decoded.url)
        XCTAssertEqual(reporter.records.count, 1)
        XCTAssertEqual(reporter.records.first?.message, "Set optional to nil due to invalid value")
    }
    
    func testLossyOptionalArrayInvalidTypeBecomesNil() throws
    {
        struct Payload: Decodable
        {
            @Lossy var values: [Int]?
        }
        
        let data = #"{"values":"bad"}"#.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let reporter = TestLossyReporter()
        decoder.setLossyReporter(reporter)
        
        let decoded = try decoder.decode(Payload.self, from: data)
        
        XCTAssertNil(decoded.values)
        XCTAssertEqual(reporter.records.count, 1)
        XCTAssertEqual(reporter.records.first?.message, "Expected array but found incompatible value; set optional array to nil")
    }
    
    func testLossyOptionalArrayDropsInvalidElements() throws
    {
        struct Payload: Decodable
        {
            @Lossy var values: [Int]?
        }
        
        let data = #"{"values":[1,"bad",2]}"#.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let reporter = TestLossyReporter()
        decoder.setLossyReporter(reporter)
        
        let decoded = try decoder.decode(Payload.self, from: data)
        
        XCTAssertEqual(decoded.values, [1, 2])
        XCTAssertEqual(reporter.records.count, 1)
        XCTAssertEqual(reporter.records.first?.message, "Dropped invalid array element at Index 1")
    }
    
    func testLossyMissingKeysUseDefaults() throws
    {
        struct Payload: Decodable
        {
            @Lossy var values: [Int]
            @Lossy var optionalValues: [Int]?
            @Lossy var optionalURL: URL?
        }
        
        let data = #"{}"#.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let reporter = TestLossyReporter()
        decoder.setLossyReporter(reporter)
        
        let decoded = try decoder.decode(Payload.self, from: data)
        
        XCTAssertEqual(decoded.values, [])
        XCTAssertNil(decoded.optionalValues)
        XCTAssertNil(decoded.optionalURL)
        XCTAssertEqual(reporter.records.count, 0)
    }
    
    func testLossyFeedbackFileUploadResultDecodes() throws
    {
        struct FeedbackFileUploadResult: Decodable
        {
            struct _Data: Codable
            {
                enum ItemType: String, Codable
                {
                    case file = "file"
                    case folder = "folder"
                }
                
                @Lossy var createTime: Int
                @Lossy var downloadPage: URL
                @Lossy var guestToken: String
                @Lossy var id: UUID
                @Lossy var md5: String
                @Lossy var mimetype: String
                @Lossy var modTime: Int
                @Lossy var name: String
                @Lossy var parentFolder: String
                @Lossy var parentFolderCode: String
                @Lossy var servers: [String]
                @Lossy var size: Int
                @Lossy var type: ItemType?
            }
            
            let status: String
            @Lossy var data: _Data
        }
        
        let json = """
        {
          "data": {
            "createTime": 1768824323,
            "downloadPage": "https://gofile.io/d/fshGmN",
            "guestToken": "9kVpeS0TWI0MxmmAsu1Gh1xXtAwQnstU",
            "id": "9f4c92da-3a43-4106-afcf-6bd5fc3a7d9a",
            "md5": "759d07691a750db0afe1a8d257348735",
            "mimetype": "application/zip",
            "modTime": 1768824323,
            "name": "file.zip",
            "parentFolder": "d85e7381-a65a-4155-a5d9-993bfa8a9c38",
            "parentFolderCode": "fshGmN",
            "servers": [
              "cold-eu-agl-1"
            ],
            "size": 7879309,
            "type": "file"
          },
          "status": "ok"
        }
        """
        
        let decoder = JSONDecoder()
        let reporter = TestLossyReporter()
        decoder.setLossyReporter(reporter)
        
        let decoded = try decoder.decode(FeedbackFileUploadResult.self, from: Data(json.utf8))
        
        XCTAssertEqual(decoded.status, "ok")
        XCTAssertEqual(decoded.data.createTime, 1768824323)
        XCTAssertEqual(decoded.data.downloadPage, URL(string: "https://gofile.io/d/fshGmN"))
        XCTAssertEqual(decoded.data.guestToken, "9kVpeS0TWI0MxmmAsu1Gh1xXtAwQnstU")
        XCTAssertEqual(decoded.data.id, UUID(uuidString: "9f4c92da-3a43-4106-afcf-6bd5fc3a7d9a"))
        XCTAssertEqual(decoded.data.md5, "759d07691a750db0afe1a8d257348735")
        XCTAssertEqual(decoded.data.mimetype, "application/zip")
        XCTAssertEqual(decoded.data.modTime, 1768824323)
        XCTAssertEqual(decoded.data.name, "file.zip")
        XCTAssertEqual(decoded.data.parentFolder, "d85e7381-a65a-4155-a5d9-993bfa8a9c38")
        XCTAssertEqual(decoded.data.parentFolderCode, "fshGmN")
        XCTAssertEqual(decoded.data.servers, ["cold-eu-agl-1"])
        XCTAssertEqual(decoded.data.size, 7879309)
        XCTAssertEqual(decoded.data.type, .file)
        XCTAssertEqual(reporter.records.count, 0)
    }
}
