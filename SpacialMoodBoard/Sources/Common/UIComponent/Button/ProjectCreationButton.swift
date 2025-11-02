//
//  ProjectCreateButton.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/12/25.
//

import SwiftUI

struct ProjectCreationButton: View {
    let onCreate: () -> Void

    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(white: 217 / 255).opacity(0.2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(320 / 250, contentMode: .fit)

                Button(action: onCreate) {
                    ZStack {
                        // Gradient filled circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(white: 153 / 255),
                                        Color.white
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(0.5)
                            .frame(width: 88, height: 88)

                        // White stroke border
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 4)
                            .frame(width: 84, height: 84)

                        // Plus sign
                        ZStack {
                            // Horizontal line
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 36.928, height: 6)

                            // Vertical line
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 6, height: 36.928)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Text("새 프로젝트")
                .font(.system(size: 20))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

#Preview {
    ProjectCreationButton {}
}
