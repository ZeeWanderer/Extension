//
//  CoreGraphicsExtensionTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import XCTest
@testable import FoundationExtension
@testable import AccelerateExtension
@testable import CoreGraphicsExtension
@testable import SwiftExtension

#if canImport(CoreGraphics)
final class CoreGraphicsExtensionTests: XCTestCase
{
    func testBoundingBoxValidity()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        let r3 = CGRect(origin: CGPoint(x: 1000, y: 200), size: CGSize(width: 100, height: 100))
        let result1 = r1.union(r2)
        let result2 = union([r1, r2])
        
        XCTAssertEqual(result1, result2)
        
        let result3 = result1.union(r3)
        let result4 = union([r1, r2, r3])
        
        XCTAssertEqual(result3, result4)
    }
    
    func testBoundingBox2Performance()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        
        measure {
            let _ = r1.union(r2)
        }
    }
    
    func testBoundingBox3Performance()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        let r3 = CGRect(origin: CGPoint(x: 1000, y: 200), size: CGSize(width: 100, height: 100))
        
        measure {
            let result1 = r1.union(r2)
            let _ = result1.union(r3)
        }
    }
    
    func testBoundingBoxArray2Performance()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        
        measure {
            let _ = union([r1, r2])
        }
    }
    
    func testBoundingBoxArray3Performance()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        let r3 = CGRect(origin: CGPoint(x: 1000, y: 200), size: CGSize(width: 100, height: 100))
        
        measure {
            let _ = union([r1, r2, r3])
        }
    }
    
    func testLerpValidity()
    {
        let r0: Double = lerp(0.5, min: 0.0, max: 10.0)
        let r1: Double = lerp(0.5, min: 0.0, max: 10.0)
        let r2: Double = lerp(1.0, min: 0.0, max: 10.0)
        
        XCTAssertEqual(r0, r1)
        XCTAssertEqual(r0, 5)
        XCTAssertEqual(r2, 10)
    }
    
    func testBinaryRepresentable()
    {
        let r1 = Array<Int>([0, 1, 2, 3])
        let r1d = r1.data
        let r1c = Array<Int>(data: r1d)
        
        struct Test0: Equatable, SafeBinaryRepresentable
        {
            let int0: Int
            let int1: Int
        }
        
        let t0: Test0 = .init(int0: 0, int1: 1)
        let t0r: Data = t0.data
        let t0r1 = Test0(data: t0r)
        
        let t1: CGRect = .init(x: 1, y: 2, width: 4, height: 5)
        let t1r: Data = t1.data
        let t1r1 = CGRect(data: t1r)
        
        let t2: [Double] = [1, 2, 4, 5]
        let t2r: Data = t2.data
        let t2r1 = CGRect(data: t2r)
        
        let t3: [Double] = [1, 2, 4]
        let t3r: Data = t3.data
        let t3r1 = CGRect(validating: t3r)
        
        let r2 = Array<Test0>([.init(int0: 0, int1: 1), .init(int0: 2, int1: 3)])
        let r2d = r2.data
        let r2c = Array<Test0>(data: r2d)
        
        let r3 = Set<Int>([1,2,3])
        let r3d = r3.data
        let r3c = Set<Int>(data: r3d)
        
        XCTAssertEqual(r1, r1c)
        XCTAssertEqual(r2, r2c)
        XCTAssertEqual(r3, r3c)
        XCTAssertEqual(t0, t0r1)
        XCTAssertEqual(t1, t1r1)
        XCTAssertEqual(t1, t2r1)
        XCTAssertEqual(nil, t3r1)
    }
}
#endif
