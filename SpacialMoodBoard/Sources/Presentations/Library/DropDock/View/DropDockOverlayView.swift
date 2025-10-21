//
//  DropDockOverlayView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import PhotosUI

struct DropDockOverlayView: View {
    
    // MARK: - Properties
    
    @Binding private var isPresented: Bool
    private let onDropProviders: ([NSItemProvider]) -> Bool

    @State private var viewModel: DropDockOverlayViewModel

    // MARK: - Init

    /// 드롭 도크(가져오기 오버레이) 뷰 초기화
    /// - Parameters:
    ///   - isPresented: 오버레이 표시 여부 바인딩. `true`로 설정하면 표시되고, 성공 처리 시 자동으로 `false`로 전환
    ///   - onDropProviders: 드래그/선택/붙여넣기로 모은 `NSItemProvider` 배열을 상위로 전달해 실제 Import 처리를 수행하는 콜백
    ///                      성공하면 `true` 반환
    init(
        isPresented: Binding<Bool>,
        onDropProviders: @escaping ([NSItemProvider]) -> Bool
    ) {
        self._isPresented = isPresented
        self.onDropProviders = onDropProviders
        self._viewModel = State(
            initialValue: DropDockOverlayViewModel(
                sendProviders: onDropProviders,
                onSuccess: { isPresented.wrappedValue = false }
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
                    CapsuleActionButton(title: "파일") {
                        viewModel.openFiles()
                    }
                    
                    PhotosPicker(selection: $viewModel.photoSelection,
                                 maxSelectionCount: 10,
                                 matching: .images) {
                        CapsuleActionLabel(title: "사진")
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)

                    CapsuleActionButton(title: "붙여넣기") {
                        viewModel.pasteFromClipboard()
                    }
                }

                if let err = viewModel.pasteError {
                    Text(err).font(.footnote).foregroundStyle(.secondary)
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
        .fileImporter(
            isPresented: $viewModel.showFileImporter,
            allowedContentTypes: [.image, .png, .jpeg, .heic],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.handleFilesPicked(urls: urls)
            case .failure(let err):
                print("파일 가져오기 실패:", err.localizedDescription)
            }
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

/// 캡슐형 Action 버튼(텍스트만)
fileprivate struct CapsuleActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CapsuleActionLabel(title: title)
        }
        .buttonStyle(.plain)
        .hoverEffectDisabled(true)
        .hoverEffect(.highlight)
    }
}

/// 캡슐형 라벨(PhotosPicker에도 재사용)
fileprivate struct CapsuleActionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .medium))
            .padding(.horizontal, 26)
            .padding(.vertical, 6.5)
            .background(.black.opacity(0.26))
            .clipShape(Capsule())
            .contentShape(Capsule())
    }
}
