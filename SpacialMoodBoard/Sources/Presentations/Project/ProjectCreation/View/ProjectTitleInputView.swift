//
//  ProjectNameInputView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/11/25.
//

import SwiftUI

struct ProjectTitleInputView: View {
  let onCreate: (String) -> Void
  
  @State private var projectName = ""
  @FocusState private var isFocused: Bool
  @State private var appeared = false
  
  var body: some View {
    VStack(spacing: 60) {
        Text("프로젝트 이름을 입력하세요")
          .font(.system(size: 40, weight: .bold))
      
      TextField("프로젝트 이름", text: $projectName)
        .font(.system(size: 28))
        .textFieldStyle(.plain)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 60)
        .padding(.vertical, 30)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .frame(maxWidth: 600)
        .focused($isFocused)
      
      Button(action: createProject) {
        Text("생성하기")
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 80)
          .padding(.vertical, 20)
          .background(
            projectName.trimmingCharacters(in: .whitespaces).isEmpty
            ? Color.gray.opacity(0.5)
            : Color.blue
          )
          .cornerRadius(20)
      }
      .buttonStyle(.plain)
      .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.bottom, 120)
    .onAppear {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        appeared = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        isFocused = true
      }
    }
  }
  
  private func createProject() {
    let trimmedName = projectName.trimmingCharacters(in: .whitespaces)
    guard !trimmedName.isEmpty else { return }
      
      // TODO: - 확인 필요, 생성하자마자 이동할려면 appModel.selectedProject에 저장 추가 필요
      // 1) Project 모델 구성
      let project = Project(
        title: trimmedName,
        projectDirectory: FilePathProvider.projectDirectory(projectName: trimmedName)
      )
      
      // 2) 디스크 저장 (폴더 생성 + JSON 저장)
      //    ProjectFileStorage는 인스턴스 메서드이므로 이렇게 호출해야 함
      let storage = ProjectFileStorage()
      do {
        try storage.save(project, projectName: trimmedName)
        print("✅ 프로젝트 초기 저장 완료")
      } catch {
        assertionFailure("프로젝트 저장 실패: \(error)")
      }
      
    withAnimation(.interpolatingSpring(stiffness: 100, damping: 15)) {
      onCreate(trimmedName)
    }
  }
}

#Preview {
  NavigationStack {
    ProjectTitleInputView { name in
      print("Project created: \(name)")
    }
  }
}
