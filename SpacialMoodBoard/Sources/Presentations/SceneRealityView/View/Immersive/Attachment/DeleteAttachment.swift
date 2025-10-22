import SwiftUI

struct DeleteAttachment: View {
    let assetName: String
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack {
            Text("'" + assetName + "'을(를) \n 삭제하시겠습니까?")
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
                Text("삭제")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Button(action: {
                onCancel()
            }) {
                Text("취소")
            }
            .buttonStyle(.bordered)
            .tint(.gray)
        }
        .padding(16)
        .glassBackgroundEffect()
    }
}

#Preview {
    DeleteAttachment(assetName: "test", onDelete: { print("삭제") }, onCancel: { print("취소") })
}