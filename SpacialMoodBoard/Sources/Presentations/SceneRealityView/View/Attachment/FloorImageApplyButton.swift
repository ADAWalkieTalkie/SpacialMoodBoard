//
//  FloorImageApplyButton.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/27/25.
//

import SwiftUI

struct FloorImageApplyButton: View {
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack {
                Color.clear
                    .background(Color(white: 217 / 255).opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(.circle)

                Image(systemName: "plus")
                    .font(.system(size: 190, weight: .semibold))
            }
            .clipShape(.circle)
            .contentShape(.circle)
            .hoverEffect()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FloorImageApplyButton {
        print("Image Apply Button Tapped")
    }
}
