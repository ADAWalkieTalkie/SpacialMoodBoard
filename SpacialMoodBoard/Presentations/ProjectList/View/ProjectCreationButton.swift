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
          .fill(.thinMaterial)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .aspectRatio(320/278, contentMode: .fit)
        
        Button(action: onCreate) {
          ZStack {
            Circle()
              .fill(Color(white: 217/255).opacity(0.5))
              .frame(width: 112, height: 112)
            
            Image(systemName: "plus")
              .font(.system(size: 64, weight: .bold))
              .foregroundStyle(.white)
          }
        }
        .buttonStyle(.plain)
      }
      
      Text("New Project")
        .font(.system(size: 20))
        .fontWeight(.bold)
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }
  }
}

#Preview {
  ProjectCreationButton { }
}
