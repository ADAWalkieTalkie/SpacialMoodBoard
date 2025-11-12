import SwiftUI

struct ToolBarToggleButton: View {
    private let type: ToolBarToggleButtonEnum
    private let action: () -> Void
    private var isSelected: Bool
    
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
                .renderingMode(.template)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(isSelected ? .black : .white)
                .frame(width: 44, height: 44)
                .background(isSelected ? .white : .clear)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .clipShape(Circle())
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .accessibilityLabel(type.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .help(type.name)
    }
}

#Preview {
    ToolBarToggleButton(type: .fullImmersive, isSelected: true, action: {})
        .environment(\.colorScheme, .dark)
    ToolBarToggleButton(type: .fullImmersive, isSelected: false, action: {})
        .environment(\.colorScheme, .dark)
}
