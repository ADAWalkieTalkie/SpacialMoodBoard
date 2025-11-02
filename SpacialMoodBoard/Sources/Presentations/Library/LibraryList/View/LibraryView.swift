//
//  LibraryView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/9/25.
//

import SwiftUI
import PhotosUI

struct LibraryView: View {
    
    // MARK: - Properties
    
    @State private var viewModel: LibraryViewModel
    @State private var sceneViewModel: SceneViewModel
    
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    // MARK: - Init
    
    /// Init
    /// - Parameter viewModel: LibraryViewModel
    init(viewModel: LibraryViewModel, sceneViewModel: SceneViewModel) {
        _viewModel = State(wrappedValue: viewModel)
        _sceneViewModel = State(wrappedValue: sceneViewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                headerView
                
                TabView(selection: $viewModel.assetType) {
                    ImageTabGridView(
                        assets: viewModel.filteredAndSorted(type: .image, key: viewModel.searchText)
                    )
                    .tabItem { Label("이미지", systemImage: "photo.fill") }
                    .tag(AssetType.image)
                    
                    SoundTabListView(
                        assets: viewModel.filteredAndSorted(type: .sound, key: viewModel.searchText)
                    )
                    .tabItem { Label("사운드", systemImage: "speaker.fill") }
                    .tag(AssetType.sound)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 20)
            .glassBackgroundEffect()
            .allowsHitTesting(!viewModel.showDropDock)
            
            if viewModel.assetType == .image, viewModel.showDropDock {
                DropDockOverlayView(
                    isPresented: $viewModel.showDropDock,
                    onDrop: { providers in
                        _ = viewModel.handleDrop(providers: providers)
                    },
                    onPhotosPicked: { items in
                        viewModel.importFromPhotos(items)
                    },
                    onPaste: {
                        viewModel.importFromClipboard()
                    },
                    onTapFile: {
                        viewModel.showFileImporter.toggle()
                    }
                )
                .ignoresSafeArea()
                .zIndex(9999)
                .transition(.topRightSlide(260))
                .allowsHitTesting(true)
            }
        }
        .fileImporter(
            isPresented: $viewModel.showFileImporter,
            allowedContentTypes: viewModel.assetType.allowedTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.importFromFileUrls(urls)
            case .failure(let err):
                print("파일 가져오기 실패:", err.localizedDescription)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showEditor) {
            ImageEditorView(
                images: viewModel.editorImages,
                projectName: viewModel.projectName
            ) { urls in
                for u in urls { Task { await viewModel.appendItem(with: u) } }
            }
        }
        .task { await viewModel.loadAssets() }
        .environment(viewModel)
        .environment(sceneViewModel)
    }
    
    // MARK: - Sub View
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 16) {
            CircleFillButton(
                type: .back,
                action: {
                    dismissWindow(id: "ImmersiveVolumeWindow")
                    appModel.selectedProject = nil
                }
            )
            
            SortSegment(selection: $viewModel.sort)
                .frame(width: 188, height: 44)
            
            Spacer()
            
            CircleFillButton(
                type: .plus,
                action: {
                    if viewModel.assetType == .image {
                        viewModel.showDropDock.toggle()
                    } else {
                        viewModel.showFileImporter.toggle()
                    }
                }
            )
            
            if viewModel.showSearch {
                CenteredVisionSearchBar(text: $viewModel.searchText)
                    .frame(width: 305, height: 44)
                    .padding(.leading, viewModel.showSearch ? 0 : -16)
                    .background(
                                OutsideTapDismiss(isActive: $viewModel.showSearch) {
                                    withAnimation(.easeInOut) { viewModel.showSearch = false }
                                }
                    )
                    
            } else {
                CircleFillButton(
                    type: .search,
                    action: { withAnimation(.easeInOut) { viewModel.showSearch = true } }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .overlay(
            Text("라이브러리")
                .font(.system(size: 29, weight: .bold)),
            alignment: .center
        )
        .padding(24)
    }
}

fileprivate struct ImageTabGridView: View {
    let assets: [Asset]
    @Environment(SceneViewModel.self) private var sceneViewModel
    
    var body: some View {
        ScrollView {
            let columns = [GridItem(.adaptive(minimum: 220, maximum: 272), spacing: 32)]
            LazyVGrid(columns: columns, spacing: 36) {
                ForEach(assets) { asset in
                    LibraryImageItemView(asset: asset)
                        .frame(width: 220, height: 272)
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                        .hoverEffect(.highlight)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                if sceneViewModel.isSelectingFloorImage {
                                    sceneViewModel.applyFloorImage(from: asset)
                                } else {
                                sceneViewModel.addImageObject(from: asset)
                                }
                            }
                        )
                }
                .padding(.horizontal, 26)
            }
        }
    }
}

fileprivate struct SoundTabListView: View {
    let assets: [Asset]
    @Environment(SceneViewModel.self) private var sceneViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(assets) { asset in
                    LibrarySoundItemView(asset: asset)
                        .frame(height: 56)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .hoverEffect(.highlight)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                sceneViewModel.addSoundObject(from: asset)
                            }
                        )
                }
            }
            .padding(.horizontal, 26)
        }
    }
}
