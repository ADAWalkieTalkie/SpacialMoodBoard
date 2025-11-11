import SwiftUI

struct DeleteAttachment: View {
    let assetName: String
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack {
            Text(String(format: String(localized: "delete.confirmation"), "'\(assetName)'"))
                .font(.system(size: 20))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.white)
                .frame(width: 300, height: 100)

            Divider()

            Button(action: {
                onDelete()
            }) {
                Text(String(localized: "action.delete"))
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Button(action: {
                onCancel()
            }) {
                Text(String(localized: "action.cancel"))
            }
            .buttonStyle(.bordered)
            .tint(.gray)
        }
        .padding(16)
        .glassBackgroundEffect()
    }
}

#Preview {
    DeleteAttachment(assetName: "test", onDelete: { print("Delete") }, onCancel: { print("Cancel") })
}