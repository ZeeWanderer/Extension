//
//  File.swift
//  
//
//  Created by Maksym Kulyk on 27.03.2024.
//

import SwiftUI
import UIKit
import UIKitExtension

public extension View {
    @MainActor
    @inlinable
    func screenShot(frame:CGRect, afterScreenUpdates: Bool) -> UIImage {
        let hosting = UIHostingController(rootView: self)
        hosting.overrideUserInterfaceStyle = UIApplication.shared.keySceneWindow?.overrideUserInterfaceStyle ?? .unspecified
        hosting.view.frame = frame
        return hosting.view.screenShot(afterScreenUpdates: afterScreenUpdates)
    }
    
    @MainActor @ViewBuilder
    @inlinable
    func screenShot(_ trigger: Binding<Bool>, closure: @escaping (UIImage)->Void, envClosure: ((Self) -> some View)? = nil) -> some View {
        self
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: trigger.wrappedValue, perform: { value in
                            @ViewBuilder
                            func envViewBuilder(_ view: Self) -> some View
                            {
                                if let envClosure { envClosure(view) }
                                else { view }
                            }
                            
                            let view_ = envViewBuilder(self)
                            
                            let image = view_.screenShot(frame: proxy.frame(in: .global), afterScreenUpdates: true)
                            
                            closure(image)
                            
                            return
                        })
                }
            }
    }
}
