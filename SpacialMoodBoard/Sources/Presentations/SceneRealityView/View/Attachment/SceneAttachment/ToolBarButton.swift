import SwiftUI

// MARK: - ToolBar Button Component

struct ToolBarButton: View {
    let systemName: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 28))
                .foregroundStyle(isEnabled ? .black : .white)
                .frame(width: 60, height: 60)
                .background(isEnabled ? Color.white : Color.clear)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}