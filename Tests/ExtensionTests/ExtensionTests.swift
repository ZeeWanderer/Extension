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
    func testExample()
    {
        debug_print("test")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
