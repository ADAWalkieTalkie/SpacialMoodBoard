//
//  ProjectItemView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/12/25.
//

import SwiftUI

struct ProjectItemView: View {
  let project: Project
  let onTitleChanged: (String) -> Void
  let onDelete: () -> Void
  
  @State private var isEditing = false
  @State private var editedTitle: String = ""
  @FocusState private var isFocused: Bool
  @State private var showDeleteAlert = false
  
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
        .aspectRatio(320 / 278, contentMode: .fit)
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
        HStack {
          Text(editedTitle.isEmpty ? project.title : editedTitle)
            .font(.system(size: 20))
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .onTapGesture {
              editedTitle = project.title
              isEditing = true
            }
          
          Button(action: {
            showDeleteAlert = true
          }) {
            Image(systemName: "trash")
              .font(.system(size: 16))
          }
          .buttonStyle(.plain)
        }
      }
    }
    .alert(
      String(
        localized: "해당 프로젝트를 삭제하시겠습니까?",
        comment: "Delete project confirmation"
      ),
      isPresented: $showDeleteAlert
    ) {
      Button(String(localized: "아니오", comment: "Cancel button"), role: .cancel) {}
      Button(
        String(localized: "예", comment: "Confirm button"),
        role: .destructive
      ) {
        onDelete()
      }
    }
  }
}

#Preview {
  ProjectItemView(
    project: Project(title: "Sample Project"),
    onTitleChanged: { _ in },
    onDelete: { }
  )
}
