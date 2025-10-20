//
//  HiddenOrSpace.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/15/25.
//

import SwiftUI

struct HiddenOrSpace<Content: View>: View {
    
    // MARK: - Properties
    
    private let show: Bool
    private let width: CGFloat?
    private let height: CGFloat?
    private let alignment: Alignment
    @ViewBuilder var content: () -> Content
    
    // MARK: - Init
    
    /// 가로/세로 크기와 정렬을 지정하는 이니셜라이저
    /// - Parameters:
    ///   - show: `true`면 콘텐츠를, `false`면 같은 크기의 빈 공간을 렌더링
    ///   - width: 고정 가로 길이. `nil`이면 부모 레이아웃을 따름
    ///   - height: 고정 세로 길이. `nil`이면 부모 레이아웃을 따름
    ///   - alignment: 프레임 내부 정렬. 기본값은 `.center`
    ///   - content: 표시할 콘텐츠 빌더
    init(
        show: Bool,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.show = show
        self.width = width
        self.height = height
        self.alignment = alignment
        self.content = content
    }
    
    /// 정사각형 크기를 지정하는 이니셜라이저
    /// - Parameters:
    ///   - show: `true`면 콘텐츠를, `false`면 같은 크기의 빈 공간을 렌더링
    ///   - size: 가로/세로 동일한 길이
    ///   - alignment: 프레임 내부 정렬. 기본값은 `.center`
    ///   - content: 표시할 콘텐츠 빌더
    init(
        show: Bool,
        size: CGFloat,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(show: show, width: size, height: size, alignment: alignment, content: content)
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if show {
                content()
            } else {
                Color.clear
            }
        }
        .frame(width: width, height: height, alignment: alignment)
    }
}
