//
//  IconCircleButton.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/15/25.
//

import SwiftUI

struct CapsuleTextButton: View {
    
    // MARK: - Properties
    
    private let title: String
    private let type: CapsuleTextButtonEnum
    private let action: () -> Void
    
    // MARK: - Init
    
    init(title: String,
         type: CapsuleTextButtonEnum,
         action: @escaping () -> Void
    ) {
        self.title = title
        self.type = type
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(type.font)
                .foregroundStyle(type.fontColor)
                .padding(.horizontal, type.horizontalPadding)
                .padding(.vertical, type.verticalPadding)
        }
        .buttonStyle(.plain)
        .background(type.background)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .hoverEffect(.highlight)
    }
}

struct CapsuleButtonStyle: ButtonStyle {
    let materialOpacity: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.white.opacity(materialOpacity), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .hoverEffect(.highlight)
            .buttonStyle(.plain)
    }
}
