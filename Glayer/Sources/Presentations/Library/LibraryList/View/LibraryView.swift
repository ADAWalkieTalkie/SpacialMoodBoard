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
    
    @State private var showAssetPlacementGuide = false
    @State private var didAddAssetsInCurrentEditorSession = false
    @AppStorage("hasSeenLibraryAssetPlacementGuide") private var hasSeenLibraryAssetPlacementGuide = false
    
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
                    LibraryImageTabGridView(
                        assets: viewModel.filteredAndSorted(type: .image, key: viewModel.searchText),
                        onAdded: { showAddedToast = true }
                    )
                    .tabItem { Label(String(localized: "library.image"), systemImage: "photo.fill") }
                    .tag(AssetType.image)
                    
                    LibrarySoundTabListView(
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
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 46, style: .continuous))
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
        .task { await viewModel.loadAssetsIfNeeded() }
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
        .onChange(of: viewModel.showEditor) { oldValue, newValue in
            if oldValue == true && newValue == false {
                if didAddAssetsInCurrentEditorSession,
                   hasSeenLibraryAssetPlacementGuide == false {
                    showAssetPlacementGuide = true
                    hasSeenLibraryAssetPlacementGuide = true
                }
                didAddAssetsInCurrentEditorSession = false
            }
        }
        // TODO: - : [발표/데모용] 프로젝트 바뀔때마다 항상 토스트 띄우고 싶을 때는 아래 코드 사용
//        .onChange(of: appStateManager.appState.selectedProject?.title) { oldValue, newValue in
//            if oldValue != newValue {
//                hasSeenLibraryAssetPlacementGuide = false
//            }
//        }
        .guidingToast(
            isPresented: $showAssetPlacementGuide,
            category: .assetPlacement
        )
        .fullScreenCover(isPresented: $viewModel.showEditor) {
            ImageEditorView(
                images: viewModel.editorImages,
                preferredNames: viewModel.editorPreferredNames,
                assetRepository: viewModel.assetRepoForEditor
            ) { urls in
                if !urls.isEmpty {
                    didAddAssetsInCurrentEditorSession = true
                    viewModel.switchToUserImages()
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
            
            if viewModel.assetType == .image {
                SortSegment(origin: $viewModel.originImageFilter)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
            } else if viewModel.assetType == .sound {
                SortSegment(origin: $viewModel.originSoundFilter)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
            }
            
        }
        .padding(24)
    }
}
