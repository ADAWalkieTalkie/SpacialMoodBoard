//
//  ImageGradientStrokeBorder.swift
//  Glayer
//
//  Created by jeongminji on 11/1/25.
//

import SwiftUI

// MARK: - ViewModifier

private struct ImageGradientStrokeBorder<S: InsettableShape>: ViewModifier {
    let shape: S
    let gradient: LinearGradient
    let lineWidth: CGFloat
    let inset: CGFloat
    let isActive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isActive {
            content.overlay(
                shape
                    .inset(by: inset)
                    .stroke(gradient, lineWidth: lineWidth)
            )
        } else {
            content
        }
    }
}

// MARK: - View Extensions

extension View {
    /// 지정된 도형(`shape`)에 따라 그라데이션 테두리 적용
    /// - Parameters:
    ///   - shape: 테두리를 적용할 도형(`Rectangle`, `Circle` 등)
    ///   - lineWidth: 테두리 두께 (기본값: 1)
    ///   - inset: 테두리를 안쪽으로 오프셋할 거리 (기본값: 0)
    ///   - isActive: 테두리 활성화 여부
    /// - Returns: 지정된 도형 형태의 그라데이션 테두리가 적용된 뷰
    func imageGradientStrokeBorder<S: InsettableShape>(
        _ shape: S,
        lineWidth: CGFloat = 5,
        inset: CGFloat = 2.5,
        isActive: Bool = true
    ) -> some View {
        modifier(ImageGradientStrokeBorder(
            shape: shape,
            gradient: LinearGradient(
                stops: [
                    .init(color: Color(hex: "D7E3FF"), location: 0.00),
                    .init(color: Color(hex: "6E95FF"), location: 0.26),
                    .init(color: Color(hex: "99B4FF"), location: 0.48),
                    .init(color: Color(hex: "CCDAFF"), location: 0.70),
                    .init(color: Color(hex: "FFFFFF"), location: 1.00)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            lineWidth: lineWidth,
            inset: inset,
            isActive: isActive
        ))
    }
}
