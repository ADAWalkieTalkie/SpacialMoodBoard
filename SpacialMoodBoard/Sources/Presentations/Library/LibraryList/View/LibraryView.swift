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
    @State private var photoSelection: [PhotosPickerItem] = []
    @Environment(AppModel.self) private var appModel
    
    // MARK: - Init
    
    /// Init
    /// - Parameter viewModel: LibraryViewModel
    init(viewModel: LibraryViewModel) {
        _viewModel = State(wrappedValue: viewModel)
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
                    onDropProviders: viewModel.handleDrop(providers:)
                )
                .ignoresSafeArea()
                .zIndex(9999)
                .transition(.topRightSlide(260))
                .allowsHitTesting(true)
            }

        }
        .fileImporter(
            isPresented: $viewModel.showSoundImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                let allowedExt = Set(["mp3","m4a","wav","aac","caf"])
                let picked = urls.filter { allowedExt.contains($0.pathExtension.lowercased()) }
                Task { await viewModel.importSoundFiles(urls: picked) }
            case .failure(let err):
                print("🎧 오디오 가져오기 실패:", err.localizedDescription)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showEditor) {
            ImageEditorView(
                images: viewModel.editorImages,
                projectName: viewModel.projectName
            ) { urls in
                for u in urls { viewModel.appendItem(with: u) }
            }
        }
        .task { await viewModel.loadAssets() }
        .environment(viewModel)
    }
    
    // MARK: - Sub View
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 16) {
            IconCircleButton(
                systemName: "chevron.left",
                action: {appModel.selectedProject = nil}
            )
            
            SortSegment(selection: $viewModel.sort)
                .frame(width: 188, height: 44)
            
            Spacer()
            
            IconCircleButton(systemName: "plus") {
                if viewModel.assetType == .image {
                    viewModel.showDropDock.toggle()
                } else {
                    viewModel.showSoundImporter.toggle()
                }
            }
            
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
                IconCircleButton(
                    systemName: "magnifyingglass",
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
    
    var body: some View {
        ScrollView {
            let columns = [GridItem(.adaptive(minimum: 220, maximum: 272), spacing: 32)]
            LazyVGrid(columns: columns, spacing: 36) {
                ForEach(assets) { asset in
                    LibraryImageItemView(asset: asset)
                        .frame(width: 220, height: 272)
                }
            }
            .padding(.horizontal, 26)
        }
    }
}

fileprivate struct SoundTabListView: View {
    let assets: [Asset]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(assets) { asset in
                    LibrarySoundItemView(asset: asset)
                        .frame(height: 56)
                }
            }
            .padding(.horizontal, 26)
        }
    }
}

// MARK: - Preview

#Preview(windowStyle: .plain) {
    LibraryView(viewModel: LibraryViewModel(appModel: AppModel()))
        .environment(AppModel())
}
