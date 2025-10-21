//
//  LibraryImageItemView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/9/25.
//

import SwiftUI

struct LibraryImageItemView: View {
    
    // MARK: - Properties
    
    private let asset: Asset
    
    @Environment(LibraryViewModel.self) private var viewModel
    @State private var showRename = false
    @State private var draftTitle: String
    @FocusState private var renameFocused: Bool
    
    // MARK: - Init
    
    /// Init
    ///  - Parameter asset: 표시할 사운드 에셋(타입은 `.image` 여야 함)
    init(asset: Asset) {
        precondition(asset.type == .image, "LibraryImageItemView는 .image 에셋만 지원합니다.")
        self.asset = asset
        self._draftTitle = State(initialValue: asset.filename.deletingPathExtension)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            URLImageView(url: asset.url)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                if showRename {
                    TextField("이름", text: $draftTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .focused($renameFocused)
                        .submitLabel(.done)
                        .onAppear { renameFocused = true }
                        .frame(maxWidth: .infinity)
                } else {
                    Text(asset.filename.deletingPathExtension)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                
                Text(Self.formatDate(asset.createdAt))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onLongPressGesture(minimumDuration: 0.35) { showRename = true }
        .popover(isPresented: $showRename, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            RenamePopover(
                id: asset.id,
                title: $draftTitle,
                onRename: { id, newTitle in viewModel.renameAsset(id: id, to: newTitle) },
                onDelete: { id in viewModel.deleteAsset(id: id) },
                onDuplicate: { id, newTitle in viewModel.duplicateAsset(id: id, as: newTitle) },
                onCancel: { showRename = false }
            )
        }
    }
    
    // MARK: - Methods

    /// Date -> "yyyy.M.d a h:mm" 포맷
    /// - Parameter date: Date
    /// - Returns: "yyyy.M.d a h:mm" 포맷
    private static func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .autoupdatingCurrent
        df.amSymbol = "AM"; df.pmSymbol = "PM"
        df.dateFormat = "yyyy.M.d a h:mm"
        return df.string(from: date)
    }
}

// MARK: - Previews

#Preview {
    LibraryImageItemView(
        asset: Asset(
            id: UUID(),
            type: .image,
            filename: "Astronaut",
            url: URL(string: "https://i.ibb.co/0yhHJbfK/image-23.png")!,
            createdAt: Date()
        )
    )
    .frame(width: 220, height: 272)
}
