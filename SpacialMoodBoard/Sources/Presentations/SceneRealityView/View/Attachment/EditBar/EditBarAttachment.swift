import SwiftUI

struct EditBarAttachment: View {
    let objectId: UUID
    let onDuplicate: () -> Void
    let onCrop: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // 복사 버튼
            EditBarAttachmentButton(systemName: "doc.on.doc", action: onDuplicate)
            
            // 크롭 버튼
            EditBarAttachmentButton(systemName: "crop", action: onCrop)
            
            // 삭제 버튼
            EditBarAttachmentButton(systemName: "trash", action: onDelete)
        }
        .padding(16)
        .glassBackgroundEffect()
    }
}

#Preview {
    EditBarAttachment(
        objectId: UUID(),
        onDuplicate: { print("복사") },
        onCrop: { print("크롭") },
        onDelete: { print("삭제") }
    )
}