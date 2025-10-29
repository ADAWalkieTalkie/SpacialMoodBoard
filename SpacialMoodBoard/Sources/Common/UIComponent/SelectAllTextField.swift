//
//  SelectAllTextField.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/28/25.
//

import SwiftUI

struct SelectAllTextField: UIViewRepresentable {
    
    // MARK: - Properties
    
    @Binding private var text: String
    @Binding private var isFirstResponder: Bool
    private var onSubmit: () -> Void = {}
    private var returnKeyType: UIReturnKeyType = .done
    
    private var alignment: NSTextAlignment = .left
    private var usesIntrinsicWidth: Bool = false
    private var minWidth: CGFloat?
    private var horizontalPadding: CGFloat = 6
    
    // MARK: - Init
    
    /// Init
    /// - Parameters:
    ///   - text: 표시/편집할 텍스트의 바인딩
    ///   - isFirstResponder: 포커스(First Responder) 제어용 바인딩
    ///   - onSubmit: 완료/엔터/포커스 아웃 시 호출될 콜백
    ///   - returnKeyType: 키보드 Return 키 타입(기본 `.done`)
    ///   - alignment: 텍스트 정렬 방식(.left / .center / .right 등)
    ///   - usesIntrinsicWidth: 텍스트 길이에 따라 내부 폭을 동적으로 계산/갱신할지 여부(true면 내용 길이에 맞춰 폭이 늘어남)
    ///   - minWidth: usesIntrinsicWidth가 true일 때 보장할 최소 폭(옵션)
    ///   - horizontalPadding: 폭 계산 시 좌우 여백(패딩) 값
    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        onSubmit: @escaping () -> Void = {},
        returnKeyType: UIReturnKeyType = .done,
        alignment: NSTextAlignment = .left,
        usesIntrinsicWidth: Bool = false,
        minWidth: CGFloat? = nil,
        horizontalPadding: CGFloat = 6
    ) {
        self._text = text
        self._isFirstResponder = isFirstResponder
        self.onSubmit = onSubmit
        self.returnKeyType = returnKeyType
        self.alignment = alignment
        self.usesIntrinsicWidth = usesIntrinsicWidth
        self.minWidth = minWidth
        self.horizontalPadding = horizontalPadding
    }
    
    // MARK: - Private wrapper view
    
    /// 연관객체 없이 UITextField를 보관하기 위한 래퍼
    final class TextFieldWrapperView: UIView {
        weak var textField: UITextField?
        var widthConstraint: NSLayoutConstraint?
    }
    
    // MARK: - Coordinator
    
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SelectAllTextField
        
        /// 부모 `SelectAllTextField`를 보관해 바인딩/콜백을 갱신하기 위함.
        /// - Parameter parent: 연결할 부모 래퍼 인스턴스.
        init(_ parent: SelectAllTextField) { self.parent = parent }
        
        /// 편집 중 텍스트가 바뀔 때 바인딩 값을 동기화.
        /// - Parameter sender: 이벤트를 보낸 `UITextField`.
        @objc func editingChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
            parent.updateWidthIfNeeded(of: sender)
        }
        
        /// Return(완료/엔터) 입력 시 제출 콜백을 호출하고 포커스를 내림.
        /// - Parameter textField: 현재 편집 중인 텍스트필드
        /// - Returns: `true`를 반환하여 기본 동작을 허용.
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            parent.isFirstResponder = false
            return true
        }
        
        /// 편집이 시작되면 다음 프레임에서 전체 선택을 수행(커서 점프 방지).
        /// - Parameter textField: 포커스를 받은 텍스트필드
        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                if let s = textField.beginningOfDocument as UITextPosition?,
                   let e = textField.endOfDocument as UITextPosition? {
                    textField.selectedTextRange = textField.textRange(from: s, to: e)
                } else {
                    textField.selectAll(nil)
                }
            }
        }
        
        /// 편집이 끝나면 제출 콜백을 호출하고 포커스를 내림(밖 터치 등 포함).
        /// - Parameter textField: 포커스를 잃은 텍스트필드
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onSubmit()
            parent.isFirstResponder = false
        }
    }
    
    // MARK: - Methods
    
    /// 코디네이터 생성자.
    /// - Returns: `Coordinator` 인스턴스
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    /// UIKit 뷰 생성: 래퍼 UIView 안에 UITextField를 오토레이아웃으로 꽉 채움
    /// - Parameter context: 컨텍스트(코디네이터 등 접근 가능)
    /// - Returns: SwiftUI가 관리할 래퍼 UIView
    func makeUIView(context: Context) -> UIView {
        let wrapper = TextFieldWrapperView()
        wrapper.clipsToBounds = true
        
        let tf = UITextField()
        tf.borderStyle = .none
        tf.font = .systemFont(ofSize: 20, weight: .bold)
        tf.textColor = .white
        tf.textAlignment = alignment
        tf.returnKeyType = returnKeyType
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.spellCheckingType = .no
        tf.delegate = context.coordinator
        tf.addTarget(context.coordinator,
                     action: #selector(Coordinator.editingChanged(_:)),
                     for: .editingChanged)
        
        tf.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(tf)
        
        let top = tf.topAnchor.constraint(equalTo: wrapper.topAnchor)
        let bottom = tf.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        let leading = tf.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor)
        let trailing = tf.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor)
        
        NSLayoutConstraint.activate([top, bottom, leading, trailing])
        
        if usesIntrinsicWidth {
            tf.removeConstraint(trailing)
            tf.removeConstraint(leading)
            let widthC = tf.widthAnchor.constraint(equalToConstant: 10)
            widthC.isActive = true
            wrapper.widthConstraint = widthC
            
            let centerX = tf.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor)
            let leadingGte = tf.leadingAnchor.constraint(greaterThanOrEqualTo: wrapper.leadingAnchor)
            let trailingLte = tf.trailingAnchor.constraint(lessThanOrEqualTo: wrapper.trailingAnchor)
            NSLayoutConstraint.activate([centerX, leadingGte, trailingLte])
        }
        
        tf.setContentCompressionResistancePriority(.required, for: .horizontal)
        tf.setContentHuggingPriority(.required, for: .horizontal)
        
        wrapper.textField = tf
        return wrapper
    }
    
    /// SwiftUI 상태를 UIKit 뷰에 반영
    /// - Parameters:
    ///   - wrapper: makeUIView에서 만든 래퍼 UIView
    ///   - context: 컨텍스트(코디네이터 등)
    func updateUIView(_ wrapper: UIView, context: Context) {
        guard let wrapper = wrapper as? TextFieldWrapperView,
              let tf = wrapper.textField else { return }
        
        if tf.text != text { tf.text = text }
        if tf.textAlignment != alignment { tf.textAlignment = alignment }
        
        updateWidthIfNeeded(of: tf)
        
        DispatchQueue.main.async {
            guard wrapper.window != nil else { return }
            if self.isFirstResponder, !tf.isFirstResponder {
                tf.becomeFirstResponder()
            } else if !self.isFirstResponder, tf.isFirstResponder {
                tf.resignFirstResponder()
            }
        }
    }
    
    /// 현재 텍스트 내용에 맞춰 텍스트필드의 너비 제약을 갱신하여 가변 폭 동작을 유지
    /// - Parameter textField: 가로 길이를 측정하고 제약을 갱신할 대상 UITextField
    private func updateWidthIfNeeded(of textField: UITextField) {
        guard usesIntrinsicWidth,
              let wrapper = textField.superview as? TextFieldWrapperView else { return }
        
        let size = (textField.text ?? "").size(
            withAttributes: [.font: textField.font ?? UIFont.systemFont(ofSize: 20, weight: .bold)]
        )
        let contentWidth = ceil(size.width) + horizontalPadding * 2
        let finalWidth = max(minWidth ?? 0, contentWidth)
        
        if wrapper.widthConstraint?.constant != finalWidth {
            wrapper.widthConstraint?.constant = finalWidth
            wrapper.layoutIfNeeded()
        }
    }
}
