//
//  GuidingToastPresenter.swift
//  Glayer
//
//  Created by jeongminji on 11/19/25.
//

import SwiftUI

private struct GuidingToastPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let category: GuidingToastMessage
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                GuidingToastView(
                    category: category,
                    isPresented: $isPresented
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(9999)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    /// GuidingToastCategory 기반으로 가이딩 토스트 표시
    /// - Parameters:
    ///   - isPresented: 표시 여부 바인딩 값
    ///   - category: 어떤 가이딩 시퀀스를 보여줄지 (예: .imageEdit, .assetPlacement)
    func guidingToast(
        isPresented: Binding<Bool>,
        category: GuidingToastMessage
    ) -> some View {
        modifier(
            GuidingToastPresenter(
                isPresented: isPresented,
                category: category
            )
        )
    }
}
