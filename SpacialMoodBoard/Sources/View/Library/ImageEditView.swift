//
//  ImageEditView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ImageImportEditor: View {
    let images: [UIImage]
    var onAddToLibrary: (_ exportedURLs: [URL]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSidebar = true
    private let sidebarWidth: CGFloat = 260

    @State private var selectedIndex: Int = 0
    @State private var showSavedAlert = false
    @State private var isAddTargeted = false
    
    private let dropTypes: [UTType] = [.image, .png, .jpeg, .heic]
    
    private var selectedImage: UIImage? {
        guard images.indices.contains(selectedIndex) else { return nil }
        return images[selectedIndex]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - 좌측 대기열(썸네일)
            
            sidebar
                .frame(width: sidebarWidth)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .frame(width: showSidebar ? sidebarWidth : 0, alignment: .leading)
                .opacity(showSidebar ? 1 : 0)
                .allowsHitTesting(showSidebar)
                .accessibilityHidden(!showSidebar)
                .animation(.easeInOut(duration: 0.22), value: showSidebar)
            
            Rectangle()
                .fill(.black.opacity(0.08))
                .frame(width: 1)
            
            // MARK: - 우측 편집영역
            
            editorCanvas
        }
    }
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("이미지 모음")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { showSidebar.toggle() }
                } label: {
                    Image(systemName: "square.split.2x1")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("l", modifiers: .command)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(images.indices, id: \.self) { i in
                        let isSelected = (i == selectedIndex)

                        Image(uiImage: images[i])
                            .resizable()
                            .scaledToFill()
                            .frame(width: sidebarWidth - 32,
                                   height: (sidebarWidth - 32) * 0.75)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.accentColor : .white.opacity(0.12),
                                            lineWidth: isSelected ? 3 : 1)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                            .onTapGesture {
                                withAnimation(.snappy) { selectedIndex = i }
                            }
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: .infinity)
            .background(.ultraThinMaterial)
        }
    }

    
    private var editorCanvas: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)

                if !showSidebar {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) { showSidebar = true }
                    } label: {
                        Image(systemName: "square.split.2x1")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 34, height: 34)
                            .background(.thinMaterial, in: Circle())
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("l", modifiers: .command)
                }

                Spacer()

                Text("이미지 편집")
                    .font(.system(size: 28, weight: .bold))

                Spacer()

                Button("라이브러리 보기") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                Button("완료") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.06))

                if let img = selectedImage {
                    SubjectLiftDragView(image: img)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .frame(width: 660, height: 447)
                } else {
                    Text("이미지가 없습니다.")
                        .foregroundStyle(.secondary)
                }

            }
            .frame(width: 660, height: 447)

            Button {
                addCurrentToLibrary()
            } label: {
                Label("라이브러리에 추가", systemImage: "folder")
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .onDrop(of: dropTypes, isTargeted: $isAddTargeted) { providers in
                handleDropToAdd(providers: providers)
            }
            .overlay {
                Capsule()
                    .stroke(isAddTargeted ? .white.opacity(0.45) : .white.opacity(0.12), lineWidth: 2)
                    .shadow(color: .white.opacity(isAddTargeted ? 0.25 : 0), radius: 10)
            }
            
            RoundedRectangle(cornerRadius: 3)
                .fill(.white.opacity(0.22))
                .frame(width: 220, height: 6)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .background(
            LinearGradient(colors: [.black.opacity(0.10), .clear],
                           startPoint: .top, endPoint: .bottom)
        )
        
        .padding(24)
        .glassBackgroundEffect()
        .alert("라이브러리에 저장되었습니다.", isPresented: $showSavedAlert) {
            Button("확인", role: .cancel) { }
        }
        .onAppear {
            if images.isEmpty == false { selectedIndex = 0 }
        }
    }

    // MARK: - Actions

    private func addCurrentToLibrary() {
        guard let img = selectedImage,
              let url = exportPNG(img) else { return }
        onAddToLibrary([url])
        showSavedAlert = true
    }

    private func handleDropToAdd(providers: [NSItemProvider]) -> Bool {
        var handled = false
        let imageUTIs = [UTType.png.identifier, UTType.jpeg.identifier, UTType.heic.identifier, UTType.image.identifier]

        for provider in providers {
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { obj, _ in
                    if let img = obj as? UIImage, let url = exportPNG(img) {
                        DispatchQueue.main.async {
                            onAddToLibrary([url])
                            showSavedAlert = true
                        }
                    }
                }
                handled = true
                continue
            }

            if let t = imageUTIs.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
                provider.loadDataRepresentation(forTypeIdentifier: t) { data, _ in
                    guard let data, let img = UIImage(data: data),
                          let url = exportPNG(img) else { return }
                    DispatchQueue.main.async {
                        onAddToLibrary([url]); showSavedAlert = true
                    }
                }
                handled = true
            }
        }
        return handled
    }

    // MARK: - Export helpers

    private func exportPNG(_ image: UIImage) -> URL? {
        let filename = UUID().uuidString + ".png"
        do {
            let dir = try FileManager.default.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
            let url = dir.appendingPathComponent(filename)
            if let data = image.pngData() {
                try data.write(to: url, options: .atomic)
                return url
            }
        } catch { }
        return nil
    }
}
