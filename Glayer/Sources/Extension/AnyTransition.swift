//
//  AnyTransition.swift
//  Glayer
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI

extension AnyTransition {
    static func topRightSlide(_ distance: CGFloat = 240) -> AnyTransition {
        let insert = AnyTransition.modifier(
            active: SlideFade(offset: CGSize(width: distance, height: -distance), opacity: 0),
            identity: SlideFade(offset: .zero, opacity: 1)
        )
        let remove = AnyTransition.modifier(
            active: SlideFade(offset: CGSize(width: distance, height: -distance), opacity: 0.01),
            identity: SlideFade(offset: .zero, opacity: 1)
        )
        return .asymmetric(insertion: insert, removal: remove)
    }
}

private struct SlideFade: ViewModifier {
    let offset: CGSize
    let opacity: CGFloat
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .opacity(opacity)
    }
}
