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
}
