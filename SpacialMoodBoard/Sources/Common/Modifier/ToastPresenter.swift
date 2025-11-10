//
//  ToastPresenter.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 11/1/25.
//

import SwiftUI

private struct ToastPresenter: ViewModifier {
    @Binding private var isPresented: Bool
    private let message: ToastMessage
    private let dismissWhen: (() -> Bool)?
    
    /// init
    /// - Parameters:
    ///   - isPresented: 토스트 표시 여부를 제어하는 바인딩 값. `true`일 때 토스트가 화면에 나타남
    ///   - message: 표시할 토스트 메시지(`ToastMessage` 열거형). 텍스트, 위치, 사운드, 해제 모드 등의 정보를 포함
    ///   - dismissWhen: `.external` 모드일 때 토스트를 닫을지 여부를 반환하는 조건 클로저(옵셔널)
    init(isPresented: Binding<Bool>, message: ToastMessage, dismissWhen: (() -> Bool)? = nil) {
        self._isPresented = isPresented
        self.message = message
        self.dismissWhen = dismissWhen
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                ToastView(
                    message: message,
                    dismissAction: { withAnimation(.easeInOut) { isPresented = false } }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: message.position))
                .transition(.opacity)
                .onAppear {
                    if let sfx = message.sfx {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            SoundFX.shared.play(sfx)
                        }
                    }
                    
                    let _: ToastDismissMode = {
                        switch message.dismissMode {
                        case .external:
                            return .external(shouldDismiss: dismissWhen)
                        default:
                            return message.dismissMode
                        }
                    }()
                    
                    switch message.dismissMode {
                    case let .auto(duration):
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.easeInOut(duration: 0.18)) { isPresented = false }
                        }
                    case let .external(shouldDismiss):
                        if let shouldDismiss {
                            Task { @MainActor in
                                while isPresented {
                                    try? await Task.sleep(for: .milliseconds(300))
                                    if shouldDismiss() {
                                        withAnimation(.easeInOut(duration: 0.18)) { isPresented = false }
                                        break
                                    }
                                }
                            }
                        }
                    case .manual:
                        break
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isPresented)
    }
    
    /// ToastPosition에 따라 Alignment를 반환
    /// - Parameter position: `.top`, `.center`, `.bottom`
    /// - Returns: 해당 위치에 맞는 Alignment 값
    private func alignment(for position: ToastPosition) -> Alignment {
        switch position {
        case .top:    return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }
}

extension View {
    /// ToastMessage enum 기반으로 토스트 표시
    /// - Parameters:
    ///   - isPresented: 표시 여부 바인딩 값
    ///   - message: ToastMessage 열거형 (title, subtitle, dismissMode, position, sfx 모두 포함)
    func toast(
        isPresented: Binding<Bool>,
        message: ToastMessage,
        dismissWhen: (() -> Bool)? = nil
    ) -> some View {
        modifier(ToastPresenter(
            isPresented: isPresented,
            message: message,
            dismissWhen: dismissWhen)
        )
    }
}
