//
//  GroundSizeSelectionView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/11/25.
//

import SwiftUI

struct GroundSizeSelectionView: View {
    let onSelect: (GroundSize) -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 40) {
            Text("공간 크기를 선택하세요")
                .font(.system(size: 40, weight: .bold))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -20)

            HStack(spacing: 40) {
                ForEach(Array(GroundSize.allCases.enumerated()), id: \.element)
                { index, size in
                    GroundSizeCard(size: size, index: index) {
                        onSelect(size)
                    }
                }
            }
            .padding(.horizontal, 62)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 120)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

struct GroundSizeCard: View {
    let size: GroundSize
    let index: Int
    let onTap: () -> Void

    @State private var appeared = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Color.clear
                    .background(Color(white: 217 / 255).opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 30))
                VStack {
                    Image(systemName: size.iconName)
                        .font(.system(size: 120))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 40)

                    Text(size.rawValue)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(
                        "\(size.dimensions.x)m × \(size.dimensions.y)m × \(size.dimensions.z)m"
                    )
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                }

            }
            .clipShape(.rect(cornerRadius: 30))
            .contentShape(.rect(cornerRadius: 30))
            .hoverEffect()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8).delay(
                    Double(index) * 0.1
                )
            ) {
                appeared = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        GroundSizeSelectionView { size in
            print("Selected: \(size)")
        }
    }
}
