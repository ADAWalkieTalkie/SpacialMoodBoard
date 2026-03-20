//
//  CropControlAttachment.swift
//  Glayer
//
//  Created by PenguinLand on 01/05/26.
//

import SwiftUI

/// 이미지 크롭 중에 표시되는 취소/완료 버튼 UI
/// CropAttachment 상단에 배치되어 사용자가 명시적으로 크롭을 완료하거나 취소할 수 있도록 함
struct CropControlAttachment: View {

    // MARK: - Properties

    let onCancel: () -> Void
    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 20) {
            // 취소 버튼
            CapsuleTextButton(
                title: String(localized: "action.cancel"),
                type: .cropCancel,
                action: onCancel
            )
            .glassBackgroundEffect()

            // 완료 버튼
            CapsuleTextButton(
                title: String(localized: "action.done"),
                type: .cropComplete,
                action: onComplete
            )
            .glassBackgroundEffect()
        }
    }
}

#Preview {
    CropControlAttachment(
        onCancel: { print("취소") },
        onComplete: { print("완료") }
    )
}
