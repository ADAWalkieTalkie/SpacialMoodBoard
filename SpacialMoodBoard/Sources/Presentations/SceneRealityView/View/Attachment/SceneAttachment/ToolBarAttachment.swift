import SwiftUI

struct ToolBarAttachment: View {
    // 각 버튼의 토글 상태
    @Binding var is3DEnabled: Bool
    @Binding var isViewEnabled: Bool
    @Binding var isPersonEnabled: Bool
    @Binding var isSoundEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 뷰 모드 버튼
            ToolBarButton(
                systemName: "eye",
                isEnabled: isViewEnabled,
                action: { isViewEnabled.toggle() }
            )
            
            // 사용자 모드 버튼
            ToolBarButton(
                systemName: "person.and.background.dotted",
                isEnabled: isPersonEnabled,
                action: { isPersonEnabled.toggle() }
            )
            
            // 사운드 버튼
            ToolBarButton(
                systemName: isSoundEnabled ? "speaker.slash" : "speaker",
                isEnabled: isSoundEnabled,
                action: { isSoundEnabled.toggle() }
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .glassBackgroundEffect()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var is3DEnabled = true
    @Previewable @State var isViewEnabled = true
    @Previewable @State var isPersonEnabled = true
    @Previewable @State var isSoundEnabled = false
    
    ToolBarAttachment(
        is3DEnabled: $is3DEnabled,
        isViewEnabled: $isViewEnabled,
        isPersonEnabled: $isPersonEnabled,
        isSoundEnabled: $isSoundEnabled
    )
}
