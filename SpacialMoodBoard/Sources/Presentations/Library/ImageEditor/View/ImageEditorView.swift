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
    init(
        images: [UIImage],
        preferredNames: [String?],
        projectName: String,
        onAddToLibrary: @escaping ([URL]) -> Void
    ) {
        _viewModel = State(
            initialValue: ImageEditorViewModel(
                images: images,
                preferredNames: preferredNames,
                assetRepository: AssetRepository(
                    project: projectName,
                    imageService: ImageAssetService(),
                    soundService: SoundAssetService()
                ),
                onAddToLibrary: onAddToLibrary
            )
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            ImageSidebarView(viewModel: viewModel)
            
            VStack(spacing: 0) {
                EditorToolbarView(viewModel: viewModel, dismiss: { dismiss() })
                ImageStageView(viewModel: viewModel)
                AddToLibraryButton(viewModel: viewModel)
            }
            .padding(.bottom, 39)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassBackgroundEffect()
        .toast(
            isPresented: $viewModel.showSavedAlert,
            message: .addToLibrary
        )
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
                
                CircleFillButton(
                    type: .sidebar,
                    action: { withAnimation(.easeInOut(duration: 0.22)) {
                        viewModel.showSidebar.toggle()}
                    }
                )
                .keyboardShortcut("l", modifiers: .command)
            }
            .padding(.leading, 28)
            .padding(.trailing, 20)
            .padding(.top, 24)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 26)], spacing: 26) {
                        ForEach(viewModel.images.indices, id: \.self) { i in
                            let isSelected = (i == viewModel.selectedIndex)
                            
                            Image(uiImage: viewModel.images[i])
                                .resizable()
                                .scaledToFit()
                                .imageGradientStrokeBorder(
                                    Rectangle()
                                    , isActive: isSelected)
                                .frame(maxWidth: 240)
                                .frame(maxHeight: 160)
                                .id(i)
                                .onTapGesture {
                                    withAnimation(.snappy) { viewModel.selectedIndex = i }
                                }
                        }
                    }
                }
                .onChange(of: viewModel.selectedIndex) { _, newValue in
                    withAnimation(.snappy) {
                        proxy.scrollTo(newValue, anchor: .center)
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
                CircleFillButton(
                    type: .sidebar,
                    action: { withAnimation(.easeInOut(duration: 0.22)) {
                        viewModel.showSidebar = true}
                    }
                )
                .keyboardShortcut("l", modifiers: .command)
            }
            
            Spacer()
            
            HStack(spacing: 24) {
                CapsuleTextButton(
                    title: "추가된 에셋",
                    type: .imageEditorView,
                    action: {viewModel.showAddedPopover = true}
                )
                .popover(isPresented: $viewModel.showAddedPopover, arrowEdge: .top) {
                    AddedAssetsPreview(urls: viewModel.addedURLs)
                        .frame(width: 380, height: 362)
                }
                
                CapsuleTextButton(
                    title: "완료",
                    type: .imageEditorView,
                    action: { dismiss() }
                )
            }
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
        HStack(alignment: .center, spacing: 40) {
            HiddenOrSpace(show: (viewModel.images.count > 1 && !viewModel.isFirst), size: 44) {
                CircleFillButton(
                    type: .back,
                    action: { viewModel.prevImage() }
                )
            }
            
            VStack(spacing: 12) {
                Text("\(viewModel.images.isEmpty ? 0 : viewModel.selectedIndex + 1)/\(viewModel.images.count)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                if let img = viewModel.selectedImage {
                    SubjectLiftDragView(image: img)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .id(viewModel.selectedIndex)
                        .contentShape(Rectangle())
                        .keyboardShortcut(.leftArrow, modifiers: [])
                        .keyboardShortcut(.rightArrow, modifiers: [])
                } else {
                    Text("이미지가 없습니다.")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity)
            
            HiddenOrSpace(show: (viewModel.images.count > 1 && !viewModel.isLast), size: 44) {
                CircleFillButton(
                    type: .next,
                    action: { viewModel.nextImage() }
                )
            }
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, viewModel.showSidebar ? 86 : 246)
    }
}

/// 라이브러리 추가 버튼
fileprivate struct AddToLibraryButton: View {
    @Bindable var viewModel: ImageEditorViewModel
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack {
            Button(action: viewModel.addCurrentToLibrary) {
                Text("라이브러리에 추가")
                    .font(.system(size: 19, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
            }
            .buttonStyle(CapsuleButtonStyle(materialOpacity: 0.3))
            .background(.clear)
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0.00),
                        .init(color: Color(red: 0.43, green: 0.49, blue: 1).opacity(0.5), location: 0.52),
                        .init(color: .white, location: 1.00),
                    ],
                    startPoint: .init(x: 0, y: 0.5),
                    endPoint: .init(x: 1, y: 0.5)
                )
                .blur(radius: 15)
                .opacity( viewModel.isAddTargeted ? 0.5 : 0.0)
            )
            .scaleEffect(scale)
            .contentShape(Capsule())
        }
        .frame(height: 104)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 140)
        .onDrop(of: viewModel.dropTypes, isTargeted: $viewModel.isAddTargeted) { providers in
            viewModel.handleDropToAdd(providers: providers)
        }
        .onChange(of: viewModel.isAddTargeted) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    scale = 1.16
                }
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        }
    }
}
