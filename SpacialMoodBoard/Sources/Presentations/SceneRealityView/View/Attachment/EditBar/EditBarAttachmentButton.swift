import SwiftUI

struct EditBarAttachmentButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
}