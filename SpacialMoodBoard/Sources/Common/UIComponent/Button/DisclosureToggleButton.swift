//
//  DisclosureToggleButton.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 11/4/25.
//

import SwiftUI

struct DisclosureToggleButton: View {
    
    // MARK: - Properties
    
    private let title: String
    private let isExpanded: Bool
    private let action: () -> Void
    
    // MARK: - Init
    
    init(
        title: String,
        isExpanded: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isExpanded = isExpanded
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 20, weight: .regular))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .clipShape(Capsule())
        .contentShape(Capsule())
    }
}
