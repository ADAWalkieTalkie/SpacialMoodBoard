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
    
    // MARK: - Init
    
    /// Init
    /// - Parameters:
    ///   - text: 표시/편집할 텍스트의 바인딩
    ///   - isFirstResponder: 포커스(First Responder) 제어용 바인딩
    ///   - onSubmit: 완료/엔터/포커스 아웃 시 호출될 콜백
    ///   - returnKeyType: 키보드 Return 키 타입(기본 `.done`)
    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        onSubmit: @escaping () -> Void = {},
        returnKeyType: UIReturnKeyType = .done
    ) {
        self._text = text
        self._isFirstResponder = isFirstResponder
        self.onSubmit = onSubmit
        self.returnKeyType = returnKeyType
    }
    
    // MARK: - Private wrapper view
    
    /// 연관객체 없이 UITextField를 보관하기 위한 래퍼
    final class TextFieldWrapperView: UIView {
        weak var textField: UITextField?
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
        NSLayoutConstraint.activate([
            tf.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            tf.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            tf.topAnchor.constraint(equalTo: wrapper.topAnchor),
            tf.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        
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
        
        DispatchQueue.main.async {
            guard wrapper.window != nil else { return }
            if self.isFirstResponder, !tf.isFirstResponder {
                tf.becomeFirstResponder()
            } else if !self.isFirstResponder, tf.isFirstResponder {
                tf.resignFirstResponder()
            }
        }
    }
}
