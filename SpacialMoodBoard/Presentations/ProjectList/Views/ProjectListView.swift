//
//  ProjectListView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import SwiftUI

struct ProjectListView: View {
  @State private var viewModel = ProjectListViewModel()
  
  let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 3)
  
  @State private var searchText = ""
  
  var filteredProjects: [Project] {
    if searchText.isEmpty {
      return viewModel.projects
    } else {
      return viewModel.projects.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 40) {
          ForEach(filteredProjects) { project in
            ProjectItemView(project: project) { newTitle in
              viewModel.updateProjectTitle(projectId: project.id, newTitle: newTitle)
            }
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
  
  let onTitleChanged: (String) -> Void
  
  @State private var isEditing = false
  @State private var editedTitle: String = ""
  @FocusState private var isFocused: Bool
  
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
      
      if isEditing {
        TextField("ProjectTitle", text: $editedTitle)
          .font(.system(size: 20))
          .fontWeight(.bold)
          .multilineTextAlignment(.center)
          .focused($isFocused)
          .onSubmit {
            if !editedTitle.trimmingCharacters(in: .whitespaces).isEmpty {
              onTitleChanged(editedTitle)
            }
            isEditing = false
          }
          .onAppear {
            isFocused = true
          }
        
      } else {
        Text(editedTitle.isEmpty ? project.title : editedTitle)
          .font(.system(size: 20))
          .fontWeight(.bold)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .onTapGesture {
            editedTitle = project.title
            isEditing = true
          }
      }
    }
  }
}

#Preview {
  ProjectListView()
}
