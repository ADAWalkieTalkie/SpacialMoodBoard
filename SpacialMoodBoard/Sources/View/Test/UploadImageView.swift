//
//  UploadImageView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/5/25.
//

import SwiftUI
import PhotosUI

struct UploadImageView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var uiImage: UIImage?

    var body: some View {
        VStack(spacing: 24) {
            // 미리보기
            Group {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 600, maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 8)
                } else {
                    ContentUnavailableView("No Image",
                                           systemImage: "photo.on.rectangle.angled",
                                           description: Text("Pick a photo to preview"))
                        .frame(maxWidth: 600, maxHeight: 300)
                }
            }

            // 사진 선택 버튼
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Choose Photo", systemImage: "photo")
                    .font(.headline)
            }
        }
        .padding(32)
        .onChange(of: selectedItem) { _, newValue in
            Task {
                guard
                    let data = try? await newValue?.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else { return }
                uiImage = image
            }
        }
    }
}

#Preview {
    UploadImageView()
}
