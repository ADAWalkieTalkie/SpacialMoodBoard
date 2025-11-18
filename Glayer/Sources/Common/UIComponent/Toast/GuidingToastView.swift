//
//  GuidingToastView.swift
//  Glayer
//
//  Created by jeongminji on 11/19/25.
//

import SwiftUI

struct GuidingToastView: View {
    
    // MARK: - Properties
    
    private let category: GuidingToastMessage
    @Binding private var isPresented: Bool
    
    @State private var currentIndex: Int = 0
    private var steps: [GuidingToastModel] {
        category.steps
    }
    
    // MARK: - Init
    
    /// GuidingToastView 생성자
    /// - Parameters:
    ///   - category: 표시할 가이딩 토스트의 카테고리 (이미지 편집 / 에셋 배치 등)
    ///   - isPresented: 토스트 표시 여부를 제어하는 바인딩 값
    init(category: GuidingToastMessage, isPresented: Binding<Bool>) {
        self.category = category
        self._isPresented = isPresented
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            headerCloseButton
            contentTabView
            pageIndicator
            Divider()
                .padding(.vertical, 10)
            confirmButton
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .frame(width: 436)
        .glassBackgroundEffect()
    }
}

// MARK: - Subviews

fileprivate extension GuidingToastView {
    
    // MARK: 취소 버튼
    
    var headerCloseButton: some View {
        CircleFillButton(
            type: .cancel,
            action: { isPresented = false }
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: 가운데 카드 (TabView)
    
    var contentTabView: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.system(size: 17, weight: .bold))
                        
                        Text(step.description)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 9)
                    
                    LoopingVideoView(videoName: step.videoName, folderName: "GuidingVideo")
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.top, 9)
                        .padding(.bottom, 10)
                }
                .tag(index)
            }
        }
        .frame(minHeight: 345)
        .frame(maxHeight: 471)
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    // MARK: 페이지 인디케이터
    
    @ViewBuilder
    var pageIndicator: some View {
        if steps.count > 1 {
            HStack(spacing: 12) {
                ForEach(0..<steps.count, id: \.self) { idx in
                    Circle()
                        .fill(idx == currentIndex ? .white : .secondary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    // MARK: 확인 버튼
    
    var confirmButton: some View {
        Button(action: { isPresented = false }) {
            Text(String(localized: "action.confirm"))
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.plain)
        .clipShape(Capsule())
        .contentShape(Capsule())
    }
}
