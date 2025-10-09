//
//  ProjectListView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import SwiftUI

struct ProjectListView: View {
  let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 3)
  
  @State private var searchText = ""
  
  var filteredProjects: [Project] {
    if searchText.isEmpty {
      return Project.mockData
    } else {
      return Project.mockData.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 40) {
          ForEach(filteredProjects) { project in
            ProjectItemView(project: project)
              .padding(.horizontal, 30)
          }
        }
        .padding(.horizontal, 60)
      }
      .navigationTitle(Text("Projects"))
      .searchable(text: $searchText, prompt: "search")
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
