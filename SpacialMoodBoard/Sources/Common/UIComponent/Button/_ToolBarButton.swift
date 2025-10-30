import SwiftUI

struct ToolBarButton: View {
    private let type: ToolBarButtonEnum
    private let action: () -> Void
    private var isSelected: Bool
    
    @State private var isHovering = false
    @Environment(\.colorScheme) private var scheme
    
    init(type: ToolBarButtonEnum,
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
