import XCTest
@testable import SwiftExtension
@testable import FoundationExtension
@testable import CoreGraphicsExtension
@testable import UIKitExtension
@testable import SpriteKitExtension
@testable import SwiftUIExtension
@testable import GeneralExtensions

final class ExtensionTests: XCTestCase
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
}
