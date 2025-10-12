//
//  UploadFileImageView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/5/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct UploadFileImageView: View {
    @State private var selectedURL: URL?
    @State private var uiImage: UIImage?
    @State private var isFileImporterPresented = false
    
    var body: some View {
        VStack(spacing: 24) {
            
            // 이미지 미리보기
            Group {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 600, maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 8)
                } else {
                    ContentUnavailableView(
                        "No Image Selected",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Upload a PNG or JPG file")
                    )
                    .frame(maxWidth: 600, maxHeight: 300)
                }
            }
            
            // 파일 업로드 버튼
            Button {
                isFileImporterPresented = true
            } label: {
                Label("Upload Image File", systemImage: "folder.badge.plus")
                    .font(.headline)
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [
                    .png,
                    .jpeg,
                    .image // fallback
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let fileURL = urls.first {
                        selectedURL = fileURL
                        loadImage(from: fileURL)
                    }
                case .failure(let error):
                    print("❌ File import failed:", error.localizedDescription)
                }
            }
        }
        .padding(32)
    }
    
    // URL → UIImage 변환
    private func loadImage(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            uiImage = UIImage(data: data)
        } catch {
            print("❌ Failed to load image data:", error.localizedDescription)
        }
    }
}

#Preview {
    UploadFileImageView()
}
