//
//  SpriteKit.swift
//  
//
//  Created by Maksym Kulyk on 18.01.2023.
//

import SwiftUI
import SpriteKit

// MARK: - Pridge Protocols

public protocol SKSceneSwiftUI: SKScene
{
    @MainActor
    func onAppear()
    
    @MainActor
    func onDisappear()
    
    @MainActor
    var options: SpriteView.Options { get }
    
    @MainActor
    var debugOptions: SpriteView.DebugOptions { get }
    
    @MainActor
    var preferredFramesPerSecond: Int { get }
    
    @MainActor
    var transitionInit: SKTransition? { get }
    
    @MainActor
    var isPausedInit: Bool { get }
}

public extension SKSceneSwiftUI
{
    @inlinable @MainActor
    var options: SpriteView.Options
    {
        [.shouldCullNonVisibleNodes]
    }
    
    @inlinable @MainActor
    var debugOptions: SpriteView.DebugOptions
    {
        []
    }
    
    /// For initializing SpriteView
    @inlinable @MainActor
    var preferredFramesPerSecond: Int
    {
        60
    }
    
    /// For initializing SpriteView
    @inlinable @MainActor
    var transitionInit: SKTransition?
    {
        nil
    }
    
    /// For initializing SpriteView
    @inlinable @MainActor
    var isPausedInit: Bool
    {
        false
    }
}

// MARK: - SpriteView

public extension SpriteView
{
    /// Setup callbacks for SwiftUI events such as onAppear and onDisappear
    @inlinable @ViewBuilder @MainActor
    func setup(_ scene: SKSceneSwiftUI) -> some View
    {
        self
            .onAppear {
                scene.onAppear()
            }
            .onDisappear {
                scene.onDisappear()
            }
    }
}

public struct SpriteViewBuilder: View
{
    @usableFromInline internal let scene: SKSceneSwiftUI
    
    @inlinable
    init(scene: SKSceneSwiftUI)
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
