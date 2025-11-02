//
//  CircleFillButton.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/31/25.
//

import SwiftUI

struct CircleFillButton: View {
    
    // MARK: - Properties
    
    private let type: CircleFillButtonEnum
    private let action: () -> Void
    
    // MARK: - Init
    
    init(
        type: CircleFillButtonEnum,
        action: @escaping () -> Void
    ) {
        self.type = type
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            Image(systemName: type.systemName)
                .font(type.font)
        }
        .circleButtonStyle(type.buttonStyle)
        .frame(width: type.size, height: type.size)
        .clipShape(Circle())
    }
}
