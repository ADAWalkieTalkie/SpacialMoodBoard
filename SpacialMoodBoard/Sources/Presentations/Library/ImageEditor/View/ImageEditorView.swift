//
//  ImageEditorView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI

struct ImageEditorView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ImageEditorViewModel

    // MARK: - Init
    
    /// - Parameters:
        ///   - images: 편집 대상 이미지들
        ///   - projectName: 저장 대상 프로젝트 이름 (환경에서 읽지 말고 외부에서 주입)
        ///   - onAddToLibrary: 내보낸 파일 URL 배열 콜백
        init(images: [UIImage], projectName: String, onAddToLibrary: @escaping ([URL]) -> Void) {
            _viewModel = State(
                initialValue: ImageEditorViewModel(
                    images: images,
                    projectName: projectName,
                    onAddToLibrary: onAddToLibrary
                )
            )
        }

    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            ImageSidebarView(viewModel: viewModel)

            VStack(spacing: 44) {
                EditorToolbarView(viewModel: viewModel, dismiss: { dismiss() })
                ImageStageView(viewModel: viewModel)
                AddToLibraryButton(viewModel: viewModel)
            }
            .padding(.bottom, 39)
            .alert("라이브러리에 저장되었습니다.", isPresented: $viewModel.showSavedAlert) {
                Button("확인", role: .cancel) { }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassBackgroundEffect()
    }
}

// MARK: - Sub View

/// 편집 대기중인 이미지들 사이드 뷰
fileprivate struct ImageSidebarView: View {
    @Bindable var viewModel: ImageEditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("이미지 모음")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                IconCircleButton(systemName: "square.split.2x1") {
                    withAnimation(.easeInOut(duration: 0.22)) { viewModel.showSidebar.toggle() }
                }
                .keyboardShortcut("l", modifiers: .command)
            }
            .padding(.leading, 28)
            .padding(.trailing, 20)
            .padding(.top, 24)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 26)], spacing: 26) {
                    ForEach(viewModel.images.indices, id: \.self) { i in
                        let isSelected = (i == viewModel.selectedIndex)
                        
                        Image(uiImage: viewModel.images[i])
                            .resizable()
                            .scaledToFill()
                            .frame(width: viewModel.sidebarWidth - 32,
                                   height: viewModel.sidebarWidth - 32)
                            .clipped()
                            .overlay(
                                Rectangle()
                                    .strokeBorder(isSelected ? .red : .clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                withAnimation(.snappy) { viewModel.selectedIndex = i }
                            }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: viewModel.sidebarWidth)
        .background(.black.opacity(0.2))
        .frame(width: viewModel.showSidebar ? viewModel.sidebarWidth : 0, alignment: .leading)
        .opacity(viewModel.showSidebar ? 1 : 0)
        .allowsHitTesting(viewModel.showSidebar)
        .accessibilityHidden(!viewModel.showSidebar)
        .animation(.easeInOut(duration: 0.22), value: viewModel.showSidebar)
    }
}

/// 편집 중인 이미지 위 상단 툴 바
fileprivate struct EditorToolbarView: View {
    @Bindable var viewModel: ImageEditorViewModel
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            HiddenOrSpace(show: !viewModel.showSidebar, size: 44) {
                IconCircleButton(systemName: "square.split.2x1") {
                    withAnimation(.easeInOut(duration: 0.22)) { viewModel.showSidebar = true }
                }
                .keyboardShortcut("l", modifiers: .command)
            }

            Spacer()

            CapsuleTextButton(title: "추가된 에셋 보기") {
                viewModel.showAddedPopover = true
            }
            .popover(isPresented: $viewModel.showAddedPopover, arrowEdge: .top) {
                AddedAssetsPreview(urls: viewModel.addedURLs)
                    .frame(width: 380, height: 362)
            }

            CapsuleTextButton(title: "완료", prominent: false) { dismiss() }
        }
        .frame(maxWidth: .infinity)
        .overlay(
            Text("이미지 편집")
                .font(.system(size: 29, weight: .bold)),
            alignment: .center
        )
        .padding(24)
    }
}

/// 편집 중인 이미지뷰
fileprivate struct ImageStageView: View {
    @Bindable var viewModel: ImageEditorViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 49) {
            HiddenOrSpace(show: (viewModel.images.count > 1 && !viewModel.isFirst), size: 44) {
                NavButton(systemName: "chevron.left", action: viewModel.prevImage)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.06))

                if let img = viewModel.selectedImage {
                    SubjectLiftDragView(image: img)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .id(viewModel.selectedIndex)
                        .frame(maxHeight: .infinity)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                                .onEnded { value in
                                    let dx = value.translation.width
                                    if dx < -5 { viewModel.nextImage() }
                                    else if dx > 5 { viewModel.prevImage() }
                                }
                        )
                        .keyboardShortcut(.leftArrow, modifiers: [])
                        .keyboardShortcut(.rightArrow, modifiers: [])
                } else {
                    Text("이미지가 없습니다.")
                        .foregroundStyle(.secondary)
                }
            }

            HiddenOrSpace(show: (viewModel.images.count > 1 && !viewModel.isLast), size: 44) {
                NavButton(systemName: "chevron.right", action: viewModel.nextImage)
            }
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 140)
    }
}

/// 라이브러리 추가 버튼
fileprivate struct AddToLibraryButton: View {
    @Bindable var viewModel: ImageEditorViewModel

    var body: some View {
        Button(action: viewModel.addCurrentToLibrary) {
            Label("라이브러리에 추가", systemImage: "folder")
                .font(.system(size: 19, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
        .background(Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0.18))
        .background {
            if viewModel.isAddTargeted {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: Color(red: 0.6, green: 0.6, blue: 0.6), location: 1),
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            } else {
                Color.white.opacity(0.06)
            }
        }
        .onDrop(of: viewModel.dropTypes, isTargeted: $viewModel.isAddTargeted) { providers in
            viewModel.handleDropToAdd(providers: providers)
        }
        .clipShape(Capsule())

    }
}

#Preview {
    ImageEditorView(
        images: [
            UIImage(systemName: "photo")!.withTintColor(.systemBlue, renderingMode: .alwaysOriginal),
            UIImage(systemName: "photo.on.rectangle")!.withTintColor(.systemPink, renderingMode: .alwaysOriginal),
            UIImage(systemName: "photo.fill")!.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
        ],
        projectName: "",
        onAddToLibrary: { urls in
            print("Added to library:", urls)
        }
    )
}
