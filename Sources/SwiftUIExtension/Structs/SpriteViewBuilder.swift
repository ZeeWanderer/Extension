//
//  SpriteViewBuilder.swift
//
//
//  Created by zeewanderer on 21.05.2024.
//

import SwiftUI
import SpriteKit

public struct SpriteViewBuilder: View
{
    public let scene: SKSceneSwiftUI
    
    @inlinable
    public init(scene: SKSceneSwiftUI)
    {
        self.scene = scene
    }
    
    @inlinable
    public var body: some View
    {
        SpriteView(scene: scene, transition: scene.transitionInit, isPaused: scene.isPausedInit, preferredFramesPerSecond: scene.preferredFramesPerSecond, options: scene.options, debugOptions: scene.debugOptions)
            .setup(scene)
    }
}
