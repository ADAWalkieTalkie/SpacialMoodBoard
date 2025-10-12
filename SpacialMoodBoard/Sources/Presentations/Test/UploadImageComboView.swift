//
//  UploadImageComboView.swift
//  SpacialMoodBoard
//
//  Created by you on 2025/10/05
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct UploadImageComboView: View {
    @State private var uiImage: UIImage?
    @State private var isFileImporterPresented = false
    @State private var isSaving = false
    @State private var saveResultMessage: String?

    @FocusState private var pasteAreaFocused: Bool  // ⌘V 받을 영역 포커스
    @State private var isDropTargeted = false       // 드롭 하이라이트용(선택)

    var body: some View {
        VStack(spacing: 20) {

            // 미리보기
            Group {
                if let uiImage {
                    AnalyzableImageView(image: uiImage)
                                .frame(maxWidth: 640, maxHeight: 420)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 8)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                // 드롭 타깃 하이라이트(선택)
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isDropTargeted ? Color.accentColor : .clear, lineWidth: 3)

                            )
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 40, weight: .semibold))
                            Text("Drop / Paste (⌘V) / Import an image")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: 640, maxHeight: 300)
                    // 길게 눌러 나오는 컨텍스트 메뉴(수동 붙여넣기)
                    .contextMenu {
                        Button { pasteFromGeneralPasteboard() } label: {
                            Label("붙여넣기", systemImage: "doc.on.clipboard")
                        }
                    }
                }
            }
            .contentShape(Rectangle())

            // Drag & Drop: 이미지/URL 모두 수락
            .onDrop(
                of: [UTType.image, .png, .jpeg, .heic, .url, .fileURL],
                isTargeted: $isDropTargeted
            ) { providers in
                loadFromItemProviders(providers)
            }

            // ⌘V 단축키를 이 영역에서 받기 위한 포커스
            .focusable(true)
            .focused($pasteAreaFocused)

            // 진입 시 자동 포커스 + 탭 시 재포커스
            .onAppear { pasteAreaFocused = true }
            .onTapGesture { pasteAreaFocused = true }

            // 숨겨진 버튼에 ⌘V 바인딩 (포커스와 무관하게 항상 활성화하는 편이 더 안정적)
            .overlay {
                Button(action: { pasteFromGeneralPasteboard() }) {
                    EmptyView()
                }
                .keyboardShortcut("v", modifiers: .command)  // ⌘V
                .opacity(0.001)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }

            

            // 액션 버튼
            HStack(spacing: 16) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Import from Files", systemImage: "folder.badge.plus")
                }

                if let img = uiImage {
                    Button {
                        Task {
                            do {
                                let cutout = try await extractSubjectPNG(from: img)
                                saveToPhotos(cutout)  // 기존 저장 함수 사용
                                saveResultMessage = "Subject saved to Photos."
                            } catch {
                                saveResultMessage = "Subject extraction failed."
                                print("❌ extractSubjectPNG:", error.localizedDescription)
                            }
                        }
                    } label: {
                        Label("Save Subject", systemImage: "person.crop.circle.badge.plus")
                    }
                }

            }
            .buttonStyle(.borderedProminent)


            if let msg = saveResultMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.png, .jpeg, .image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { loadImage(from: url) }
            case .failure(let err):
                print("❌ fileImporter failed:", err.localizedDescription)
            }
        }
    }

    // MARK: - Loaders

    /// NSItemProvider 배열에서 첫 번째 이미지/URL 로드
    @discardableResult
    private func loadFromItemProviders(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // 1) UIImage 직접 로드
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { obj, _ in
                if let img = obj as? UIImage {
                    DispatchQueue.main.async { self.uiImage = img }
                }
            }
            return true
        }

        // 2) 바이너리 이미지 (png/jpeg/heic 등)
        let imageTypes = [UTType.image, .png, .jpeg, .heic].map { $0.identifier }
        if let t = imageTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
            provider.loadDataRepresentation(forTypeIdentifier: t) { data, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.uiImage = img }
            }
            return true
        }

        // 3) URL (file:// 또는 http(s)://)
        let urlTypes = [UTType.fileURL.identifier, UTType.url.identifier]
        if let t = urlTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
            provider.loadItem(forTypeIdentifier: t, options: nil) { item, _ in
                if let url = item as? URL {
                    handleIncomingURL(url)
                } else if let data = item as? Data,
                          let url = (try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSURL.self, from: data)) as URL? {
                    handleIncomingURL(url)
                }
            }
            return true
        }

        return false
    }

    private func handleIncomingURL(_ url: URL) {
        if url.isFileURL {
            do {
                let data = try Data(contentsOf: url)
                if let img = UIImage(data: data) {
                    DispatchQueue.main.async { self.uiImage = img }
                }
            } catch {
                print("❌ fileURL read failed:", error.localizedDescription)
            }
        } else if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.uiImage = img }
            }.resume()
        }
    }

    /// Files에서 선택한 URL → UIImage
    private func loadImage(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            if let img = UIImage(data: data) { self.uiImage = img }
        } catch {
            print("❌ loadImage failed:", error.localizedDescription)
        }
    }

    /// 일반 Pasteboard에서 이미지 붙여넣기 (⌘V/컨텍스트 메뉴)
    private func pasteFromGeneralPasteboard() {
        // 1) 직접 이미지
        if let img = UIPasteboard.general.image {
            uiImage = img
            return
        }
        // 2) 바이너리 이미지
        if let data = UIPasteboard.general.data(forPasteboardType: UTType.image.identifier),
           let img = UIImage(data: data) {
            uiImage = img
            return
        }
        // 3) URL
        if let url = UIPasteboard.general.url {
            handleIncomingURL(url); return
        }
        // 4) 문자열에 URL일 수 있음
        if let s = UIPasteboard.general.string, let url = URL(string: s) {
            handleIncomingURL(url)
        }
    }

    /// 사진 앱에 저장 (권한 필요)
    private func saveToPhotos(_ image: UIImage) {
        guard !isSaving else { return }
        isSaving = true
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.saveResultMessage = "Saved to Photos."
            self.isSaving = false
        }
    }
}

// MARK: - Preview

#Preview {
    UploadImageComboView()
}
