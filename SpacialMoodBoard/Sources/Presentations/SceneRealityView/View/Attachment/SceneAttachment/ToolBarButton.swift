import SwiftUI

// MARK: - ToolBar Button Component

struct ToolBarButton: View {
    let systemName: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 19))
                .foregroundStyle(isEnabled ? .black : .white)
                .frame(width: 44, height: 44)
                .background(isEnabled ? Color.white : Color.clear)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}