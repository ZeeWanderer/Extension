//
//  SpriteKitExtensionPublicAPITests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import XCTest
import SpriteKitExtension

#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
#endif

@MainActor
final class SpriteKitExtensionPublicAPITests: XCTestCase {
    #if canImport(SpriteKit) && canImport(UIKit)
    func testSceneScreenshotGetterRemainsPublic() {
        let getter: @MainActor (SKScene) -> UIImage = { scene in
            scene.screenShot
        }

        _ = getter
    }

    func testDetachedSceneViewCannotProduceACompositeScreenshot() {
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 16, height: 9))
        let scene = SKScene(size: view.bounds.size)
        view.presentScene(scene)

        XCTAssertNil(view.superview)
        XCTAssertNil(scene.screenShot_composite)
    }
    #else
    func testModuleImportsWhenUIKitSurfaceIsUnavailable() throws {
        throw XCTSkip("SpriteKitExtension screenshot APIs require UIKit")
    }
    #endif
}
