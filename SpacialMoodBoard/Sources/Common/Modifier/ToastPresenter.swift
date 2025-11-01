//
//  ToastPresenter.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 11/1/25.
//

import SwiftUI

enum ToastPosition { case top, center, bottom }

private struct ToastPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let text: String
    let subText: String
    let duration: TimeInterval
    let position: ToastPosition
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                ToastView(text: text, subText: subText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: position))
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.easeInOut(duration: 0.18)) { isPresented = false }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isPresented)
    }
    
    private func alignment(for position: ToastPosition) -> Alignment {
        switch position {
        case .top:    return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }
}

extension View {
    /// 텍스트와 서브텍스트가 포함된 토스트를 표시합니다. 지정된 시간 후 자동으로 사라짐
    /// - Parameters:
    ///   - isPresented: 토스트 표시 여부를 제어하는 바인딩 값입니다. `true`로 설정 시 토스트가 나타나며, 일정 시간이 지나면 자동으로 `false`로 변경됨
    ///   - text: 토스트의 메인 텍스트.  예: `"라이브러리에 저장되었습니다."`
    ///   - subText: 토스트 하단에 표시할 보조 텍스트. 예: `"사진 3장이 추가됨"`
    ///   - duration: 토스트가 화면에 표시되는 지속 시간(초). 기본값은 2초
    ///   - position: 토스트가 표시될 위치. `.top`, `.center`, `.bottom` 중 하나를 선택 가능. 기본값 .center
    /// - Returns: 토스트가 적용된 뷰를 반환.
    func toast(isPresented: Binding<Bool>,
               text: String,
               subText: String,
               duration: TimeInterval = 2.0,
               position: ToastPosition = .center) -> some View {
        modifier(ToastPresenter(isPresented: isPresented,
                                text: text,
                                subText: subText,
                                duration: duration,
                                position: position))
    }
}
