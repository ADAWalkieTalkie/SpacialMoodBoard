//
//  IconCircleButton.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/15/25.
//

import SwiftUI

// TODO: - 디자인 시스템 나온 후 컴포넌트화 예정
// 지금은 버튼 여백, 폰트, 색상 다 달라서 일단 ImageEditor에서 여러번 쓰이는 애들만 각각 다른 컴포넌트화

struct CapsuleTextButton: View {
    let title: String
    var prominent: Bool = false
    let action: () -> Void
    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .hoverEffectDisabled(true)
            .font(.system(size: 19, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(.gray.opacity(prominent ? 0.7 : 0.5), in: Capsule())
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
