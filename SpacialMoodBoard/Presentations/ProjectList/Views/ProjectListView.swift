//
//  ProjectListView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import SwiftUI

struct ProjectListView: View {
  let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 3)
  
  var body: some View {
    VStack {
      HStack {
        Text("Projects")
          .font(.largeTitle)
          .fontWeight(.semibold)

          Spacer()
                  
      }
      .padding(40)
      ScrollView {          
        LazyVGrid(columns: columns, spacing: 40) {
          ForEach(Project.mockData) { project in
            ProjectItemView(project: project)
              .padding(.horizontal, 30)
          }
        }
        .padding(.horizontal, 60)
      }
    }
    .glassBackgroundEffect()
  }
}

struct ProjectItemView: View {
  let project: Project
  
  var body: some View {
    VStack {
      Image(systemName: project.thumbnailImage ?? "cube.transparent")
        .font(.system(size: 40))
        .foregroundStyle(.primary)
        .frame(width: 80, height: 80)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
        )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .aspectRatio(320/278, contentMode: .fit)
    .background(.thinMaterial)
    .cornerRadius(30)
    Text(project.title)
      .font(.system(size: 20))
      .fontWeight(.bold)
      .multilineTextAlignment(.center)
      .lineLimit(2)
  }
  }
}

#Preview {
    ProjectListView()
}
