//
//  ClearBackgroundView.swift
//  
//
//  Created by Maksym Kulyk on 21.05.2024.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

/// A hack to get access to `UIView.backgroundColor` of modal superview. Remove when this functionality beomes available in SwiftUI.
public struct ClearBackgroundView: UIViewRepresentable
{
    @inlinable
    public init() {} // for @inlinable
    
    @inlinable
    public func makeUIView(context: Context) -> some UIView
    {
        let view = UIView()
        Task {
            await MainActor.run {
                view.superview?.superview?.backgroundColor = .clear
            }
        }
        return view
    }
    
    @inlinable
    public func updateUIView(_ uiView: UIViewType, context: Context)
    {
    }
}
#endif
