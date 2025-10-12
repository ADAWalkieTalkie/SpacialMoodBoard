//
//  DropDockOverlayView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct DropDockOverlayView: View {
    @Binding var isPresented: Bool
    var onDropProviders: ([NSItemProvider]) -> Bool

    @State private var isTargeted = false
    @State private var pasteError: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(alignment: .center, spacing: 16) {
                Text("Import image")
                    .font(.system(size: 17, weight: .bold))

                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 27, weight: .medium))
                    Text("Drop an image")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .frame(width: 332, height: 276)
                .background(.black.opacity(0.26))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isTargeted ? .white.opacity(0.18) : .white.opacity(0.10), lineWidth: 1)
                )
                
                .contentShape(Rectangle())

                // 임시
                Button {
                    pasteFromClipboard()
                } label: {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if let err = pasteError {
                    Text(err).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .onDrop(of: [UTType.image, .png, .jpeg, .heic, .fileURL, .url],
                    isTargeted: $isTargeted,
                    perform: onDropProviders)
            .padding(24)
            .glassBackgroundEffect()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 90)
        }
        .animation(.smooth, value: isPresented)
    }

    // MARK: - Paste handling

    private func pasteFromClipboard() {
        var providers: [NSItemProvider] = []

        // 1) 직접 이미지
        if let img = UIPasteboard.general.image {
            providers = [NSItemProvider(object: img)]
            finishPaste(with: providers)
            return
        }

        // 2) 바이너리 이미지 (공용 타입)
        if let data = UIPasteboard.general.data(forPasteboardType: UTType.image.identifier) {
            if let url = writeTemp(data: data, ext: "png") {
                if let p = NSItemProvider(contentsOf: url) { providers = [p]; finishPaste(with: providers); return }
            }
        }

        // 3) URL (file/http)
        if let url = UIPasteboard.general.url {
            if let p = NSItemProvider(contentsOf: url) { providers = [p]; finishPaste(with: providers); return }
        }

        // 4) 문자열 → URL 시도
        if let s = UIPasteboard.general.string, let url = URL(string: s) {
            if let p = NSItemProvider(contentsOf: url) { providers = [p]; finishPaste(with: providers); return }
        }

        pasteError = "클립보드에서 가져올 이미지/URL이 없어요."
    }

    private func finishPaste(with providers: [NSItemProvider]) {
        let ok = onDropProviders(providers)
        if ok { isPresented = false }
        else { pasteError = "붙여넣기 처리에 실패했어요." }
    }

    private func writeTemp(data: Data, ext: String) -> URL? {
        let name = UUID().uuidString + "." + ext
        do {
            let dir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let url = dir.appendingPathComponent(name)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            pasteError = "임시 파일 저장 실패"
            return nil
        }
    }
}
