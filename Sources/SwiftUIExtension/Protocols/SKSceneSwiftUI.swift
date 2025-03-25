//
//  SKSceneSwiftUI.swift
//
//
//  Created by zeewanderer on 21.05.2024.
//

import SwiftUI
import SpriteKit

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
