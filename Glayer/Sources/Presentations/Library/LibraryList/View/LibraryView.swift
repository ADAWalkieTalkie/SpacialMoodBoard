//
//  LibraryView.swift
//  Glayer
//
//  Created by jeongminji on 10/9/25.
//

import SwiftUI
import PhotosUI

struct LibraryView: View {
    
    // MARK: - Properties
    
    @State private var viewModel: LibraryViewModel
    @State private var sceneViewModel: SceneViewModel
    @State private var photoSelection: [PhotosPickerItem] = []
    @State private var showLoadErrorToast = false
    @State private var showLoadingToast = false
    @State private var showAddedToast = false
    @Environment(AppStateManager.self) private var appStateManager
    
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
                        assets: viewModel.filteredAndSorted(type: .image, key: viewModel.searchText),
                        onAdded: { showAddedToast = true }
                    )
                    .tabItem { Label(String(localized: "library.image"), systemImage: "photo.fill") }
                    .tag(AssetType.image)

                    SoundTabListView(
                        assets: viewModel.filteredAndSorted(type: .sound, key: viewModel.searchText),
                        onAdded: { showAddedToast = true }
                    )
                    .tabItem {
                        Label {
                            Text(String(localized: "library.sound"))
                        } icon: {
                            Image(.icBeamNote)
                                .renderingMode(.template)
                        }
                    }
                    .tag(AssetType.sound)
                }
                .toast(isPresented: $showAddedToast, message: .addToVolume)
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
        .task { await viewModel.loadAssets() }
        .onChange(of: viewModel.showLoadErrorToast) { _, now in
            showLoadErrorToast = now
        }
        .toast(
            isPresented: $showLoadErrorToast,
            message: .loadingError
        )
        .onChange(of: viewModel.isPreparingImagesToast) { _, now in
            if now { showLoadingToast = true }
            else { showLoadingToast = false }
        }
        .toast(
            isPresented: $showLoadingToast,
            message: .loadingImageEdit
        )
        .fullScreenCover(isPresented: $viewModel.showEditor) {
            ImageEditorView(
                images: viewModel.editorImages,
                preferredNames: viewModel.editorPreferredNames,
                projectName: viewModel.projectName
            ) { urls in
                Task {
                    await viewModel.loadAssets()
                }
            }
        }
        .environment(viewModel)
        .environment(sceneViewModel)
    }
    
    // MARK: - Sub View
    
    private var headerView: some View {
        VStack(spacing: 24) {
            HStack(alignment: .center, spacing: 16) {
                CircleFillButton(
                    type: .back,
                    action: {
                        appStateManager.closeProject()
                    }
                )
                
                SortSegment(sort: $viewModel.sortOrder)
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
                Text(String(localized: "library.title"))
                    .font(.system(size: 29, weight: .bold)),
                alignment: .center
            )
            
            if viewModel.assetType == .sound {
                SortSegment(origin: $viewModel.originFilter)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
    }
}

fileprivate struct ImageTabGridView: View {
    let assets: [Asset]
    let onAdded: () -> Void
    @Environment(SceneViewModel.self) private var sceneViewModel
    
    var body: some View {
        ScrollView {
            let columns = [GridItem(.adaptive(minimum: 220, maximum: 272), spacing: 32)]
            LazyVGrid(columns: columns, spacing: 36) {
                ForEach(assets) { asset in
                    LibraryImageItemView(asset: asset)
                        .frame(width: 220, height: 272)
                        .hoverEffect(.highlight)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                do {
                                    _ = try sceneViewModel.addImageObject(from: asset)
                                    onAdded()
                                } catch { }
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
    let onAdded: () -> Void
    @Environment(SceneViewModel.self) private var sceneViewModel
    @Environment(LibraryViewModel.self) private var viewModel
    
    private let channelOrder: [SoundChannel] = [.foley, .ambient]
    
    var body: some View {
        let grouped: [SoundChannel: [Asset]] =
        Dictionary(grouping: assets) { ($0.sound?.channel) ?? .ambient }
        
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.originFilter == .userOnly {
                    LazyVStack(spacing: 12) {
                        ForEach(assets) { asset in
                            LibrarySoundItemView(
                                asset: asset,
                                allowRename: true
                            ) {
                                do {
                                    _ = try sceneViewModel.addSoundObject(from: asset)
                                    onAdded()
                                } catch { }
                            }
                            .frame(height: 56)
                        }
                    }
                } else {
                    ForEach(Array(channelOrder.enumerated()), id: \.element) { index, ch in
                        let items: [Asset] = grouped[ch] ?? []
                        if !items.isEmpty {
                            VStack(spacing: 0) {
                                DisclosureToggleButton(
                                    title: ch.title,
                                    isExpanded: viewModel.isExpanded(ch),
                                    action: { viewModel.toggleChannel(ch) }
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if viewModel.isExpanded(ch) {
                                    LazyVStack(spacing: 12) {
                                        ForEach(items) { asset in
                                            LibrarySoundItemView(
                                                asset: asset,
                                                allowRename: false
                                            ) {
                                                do {
                                                    _ = try sceneViewModel.addSoundObject(from: asset)
                                                    onAdded()
                                                } catch { }
                                            }
                                            .frame(height: 56)
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .top)),
                                        removal: .opacity.combined(with: .move(edge: .top))
                                    ))
                                    .animation(.easeInOut(duration: 0.25), value: viewModel.isExpanded(ch))
                                }
                            }
                            .padding(.top, index == 0 ? 0 : 24)
                        }
                    }
                }
            }
            .padding(.horizontal, 26)
        }
    }
}
