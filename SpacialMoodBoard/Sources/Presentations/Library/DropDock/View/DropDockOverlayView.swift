//
//  DropDockOverlayView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct DropDockOverlayView: View {
    
    // MARK: - Properties
    
    @Binding private var isPresented: Bool
    private let onTapFile: () -> Void
    @State private var viewModel: DropDockOverlayViewModel
    
    // MARK: - Init
    
    /// 드롭 도크(가져오기 오버레이) 초기화
    /// - Parameters:
    ///   - isPresented: 오버레이 표시 여부 바인딩
    ///   - onDrop: 드래그&드롭 provider 전달 콜백
    ///   - onPhotosPicked: PhotosPicker 선택 콜백
    ///   - onPaste: 붙여넣기 콜백
    ///   - onTapFile: 파일 버튼 탭 시 부모에 알리는 콜백(부모가 fileImporter 표시)
    init(
        isPresented: Binding<Bool>,
        onDrop: @escaping ([NSItemProvider]) -> Void,
        onPhotosPicked: @escaping ([PhotosPickerItem]) -> Void,
        onPaste: @escaping () -> Void,
        onTapFile: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.onTapFile = onTapFile
        self._viewModel = State(
            initialValue: DropDockOverlayViewModel(
                onDrop: { providers in
                    onDrop(providers)
                    isPresented.wrappedValue = false
                },
                onPhotosPicked: { items in
                    onPhotosPicked(items)
                    isPresented.wrappedValue = false
                },
                onPaste: {
                    onPaste()
                    isPresented.wrappedValue = false
                }
            )
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            VStack(alignment: .center, spacing: 16) {
                Text("이미지 가져오기")
                    .font(.system(size: 17, weight: .bold))
                
                DropDockCard()
                
                HStack(alignment: .center, spacing: 24.5) {
                    CapsuleTextButton(
                        title: "파일",
                        type: .dropDockOverlayView,
                        action:
                            {
                                onTapFile()
                                isPresented = false
                            }
                    )
                    
                    PhotosPicker(selection: $viewModel.photoSelection,
                                 maxSelectionCount: 10,
                                 matching: .images) {
                        Text("사진")
                            .font(.system(size: 17, weight: .medium))
                            .padding(.horizontal, 26)
                            .padding(.vertical, 6.5)
                    }
                                 .buttonStyle(.plain)
                                 .background(.black.opacity(0.26))
                                 .clipShape(Capsule())
                                 .contentShape(Capsule())
                                 .hoverEffect(.highlight)
                    
                    CapsuleTextButton(
                        title: "붙여넣기",
                        type: .dropDockOverlayView,
                        action: { viewModel.pasteFromClipboard() }
                    )
                }
            }
            .onDrop(of: [UTType.image, .png, .jpeg, .heic, .fileURL, .url],
                    isTargeted: Binding(
                        get: { viewModel.isTargeted },
                        set: { viewModel.setDropTargeted($0) }
                    ),
                    perform: { providers in
                viewModel.handleOnDrop(providers: providers)
            })
            .padding(24)
            .glassBackgroundEffect()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 90)
        }
        .onChange(of: viewModel.photoSelection) { _, _ in
            Task { await viewModel.handlePhotosChanged(limit: 10) }
        }
        .animation(.smooth, value: isPresented)
    }
}

// MARK: - Sub View

/// 드롭 안내 카드
fileprivate struct DropDockCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 27, weight: .medium))
            Text("이미지 드래그 앤 드롭하기")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.primary)
        }
        .frame(width: 332, height: 276)
        .background(.black.opacity(0.26))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
