//
//  GroundSizeSelectionView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/11/25.
//

import SwiftUI

struct GroundSizeSelectionView: View {
  let onSelect: (GroundSizePreset) -> Void
  
  @State private var appeared = false
  
  var body: some View {
    VStack(spacing: 40) {
      Text("공간 크기를 선택하세요")
        .font(.system(size: 40, weight: .bold))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -20)
      
      HStack(spacing: 40) {
        ForEach(Array(GroundSizePreset.allCases.enumerated()), id: \.element) { index, preset in
          GroundSizeCard(preset: preset, index: index) {
              onSelect(preset)
          }
        }
      }
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
  let preset: GroundSizePreset
  let index: Int
  let onTap: () -> Void
  
  @State private var appeared = false
  
  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 20) {
        Image(systemName: preset.iconName)
          .font(.system(size: 80))
          .foregroundStyle(.primary)
        
        Text(preset.rawValue)
          .font(.system(size: 28, weight: .semibold))
        
        Text("\(preset.dimensions.x)m × \(preset.dimensions.y)m × \(preset.dimensions.z)m")
          .font(.system(size: 18))
          .foregroundStyle(.secondary)
      }
      .frame(width: 300, height: 300)
      .background(.ultraThinMaterial)
      .cornerRadius(30)
      .opacity(appeared ? 1 : 0)
      .offset(y: appeared ? 0 : 30)
    }
    .buttonStyle(.plain)
    .onAppear {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1)) {
        appeared = true
      }
    }
  }
}

#Preview {
  NavigationStack {
    GroundSizeSelectionView { preset in
      print("Selected: \(preset)")
    }
  }
}
