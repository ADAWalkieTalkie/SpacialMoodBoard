//
//  RoomTypeSelectionView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/11/25.
//

import SwiftUI

struct RoomTypeSelectionView: View {
  let onSelect: (RoomType) -> Void
  
  @State private var appeared = false
  
  var body: some View {
    VStack(spacing: 40) {
      Text("공간 타입을 선택하세요")
        .font(.system(size: 40, weight: .bold))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -20)
      
      HStack(spacing: 40) {
        ForEach(Array(RoomType.allCases.enumerated()), id: \.element) { index, roomType in
          RoomTypeCard(roomType: roomType, index: index) {
            onSelect(roomType)
          }
        }
      }
    }
    .padding(.bottom, 120)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        appeared = true
      }
    }
  }
}

struct RoomTypeCard: View {
  let roomType: RoomType
  let index: Int
  let onTap: () -> Void
  
  @State private var appeared = false
  
  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 20) {
        Image(systemName: roomType.iconName)
          .font(.system(size: 80))
          .foregroundStyle(.primary)
        
        Text(roomType.displayName)
          .font(.system(size: 28, weight: .semibold))
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
    RoomTypeSelectionView { roomType in
      print("Selected: \(roomType)")
    }
  }
}
