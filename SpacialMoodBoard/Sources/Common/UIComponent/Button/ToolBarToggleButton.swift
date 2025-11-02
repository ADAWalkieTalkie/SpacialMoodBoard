import SwiftUI

struct ToolBarToggleButton: View {
    private let type: ToolBarToggleButtonEnum
    private let action: () -> Void
    private var isSelected: Bool
    
    @State private var isHovering = false
    @Environment(\.colorScheme) private var scheme
    
    init(type: ToolBarToggleButtonEnum,
         isSelected: Bool,
         action: @escaping () -> Void
    ) {
        self.type = type
        self.action = action
        self.isSelected = isSelected
    }
    
    var body: some View {
        Button(action: action) {
            type.image
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(isSelected ? .black : .white)
                .frame(width: 44, height: 44)
                .background(isSelected ? .white : .clear)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.18), value: isHovering)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .accessibilityLabel(type.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .frame(width: 44, height: 44)
        .overlay(alignment: .bottom) {
            if isHovering {
                Text(type.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .glassBackgroundEffect()
                    .offset(y: 2)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

#Preview {
    ToolBarToggleButton(type: .fullImmersive, isSelected: true, action: {})
        .environment(\.colorScheme, .dark)
    ToolBarToggleButton(type: .fullImmersive, isSelected: false, action: {})
        .environment(\.colorScheme, .dark)
}
