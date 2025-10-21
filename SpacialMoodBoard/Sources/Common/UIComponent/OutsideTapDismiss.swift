//
//  OutsideTapDismiss.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

import SwiftUI

struct OutsideTapDismiss: UIViewRepresentable {
    
    // MARK: - Properties
    
    @Binding var isActive: Bool
    var onDismiss: () -> Void
    
    // MARK: - Methods
    
    /// Coordinator 생성
    /// - Returns: UIKit 제스처를 관리하는 코디네이터 인스턴스
    func makeCoordinator() -> Coordinator {
        Coordinator(isActive: $isActive, onDismiss: onDismiss)
    }
    
    /// UIKit 뷰 생성. 투명한 프록시 뷰를 만들고, 상위 뷰가 붙은 뒤에 창(Window)에 탭 제스처를 연결
    /// - Parameter context: 컨텍스트
    /// - Returns: 투명 UIView
    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.backgroundColor = .clear
        DispatchQueue.main.async { [weak v] in
            context.coordinator.targetView = v?.superview
            context.coordinator.attachIfNeeded(from: v)
        }
        return v
    }
    
    /// SwiftUI 상태 변경 시마다 UIKit 뷰/코디네이터를 갱신
    /// - Parameters:
    ///   - uiView: 재사용 중인 UIView
    ///   - context: 컨텍스트
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onDismiss = onDismiss
        context.coordinator.targetView = uiView.superview
        context.coordinator.attachIfNeeded(from: uiView)
        
        if isActive == false {
            context.coordinator.detachIfNeeded()
        }
    }
    
    // MARK: - Coordinator
    
    /// 바깥 탭 감지를 담당하는 UIKit 코디네이터
    final class Coordinator: NSObject {
        
        // MARK: - Properties
        
        let isActiveBinding: Binding<Bool>
        var onDismiss: () -> Void
        weak var targetView: UIView?
        private var tapGR: UITapGestureRecognizer?
        
        private var isActive: Bool { isActiveBinding.wrappedValue }
        
        // MARK: - Init
        
        /// Init
        /// - Parameters:
        ///   - isActive: 활성 플래그 바인딩
        ///   - onDismiss: 닫힘 콜백
        init(isActive: Binding<Bool>, onDismiss: @escaping () -> Void) {
            self.isActiveBinding = isActive
            self.onDismiss = onDismiss
        }
        
        // MARK: - Mehtods
        
        /// 필요 시 윈도우에 탭 제스처를 추가한다. 아직 윈도우가 없으면 다음 런루프에서 재시도
        /// - Parameter anchorView: 윈도우 탐색에 사용할 기준 뷰
        func attachIfNeeded(from anchorView: UIView?) {
            guard isActive, tapGR == nil else { return }
            
            guard let window = anchorView?.window ?? anchorView?.superview?.window else {
                DispatchQueue.main.async { [weak self, weak anchorView] in
                    self?.attachIfNeeded(from: anchorView)
                }
                return
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.cancelsTouchesInView = false
            window.addGestureRecognizer(tap)
            tapGR = tap
        }
        
        /// 윈도우에서 탭 제스처를 제거한다(중복 부착/메모리 누수 방지)
        func detachIfNeeded() {
            if let tap = tapGR {
                tap.view?.removeGestureRecognizer(tap)
                tapGR = nil
            }
        }
        
        /// 탭 제스처 처리: targetView 바깥을 탭하면 닫기
        /// - Parameter gr: 탭 제스처 인식기
        @objc private func handleTap(_ gr: UITapGestureRecognizer) {
            guard isActive, let target = targetView else { return }
            let p = gr.location(in: target)
            
            if !target.bounds.contains(p) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isActiveBinding.wrappedValue = false
                    self.onDismiss()
                    self.detachIfNeeded()
                }
            }
        }
    }
}
