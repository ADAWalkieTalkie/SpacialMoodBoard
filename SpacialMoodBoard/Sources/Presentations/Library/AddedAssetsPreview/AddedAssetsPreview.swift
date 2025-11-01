//
//  AddedAssetsPreview.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/14/25.
//

import SwiftUI

struct AddedAssetsPreview: View {
    
    // MARK: - Properties
    
    private let urls: [URL]
    
    // MARK: - Init
    
    /// 추가된 에셋들을 간단 그리드로 미리보기
    /// - Parameter urls: 썸네일로 보여줄 파일 URL 배열
    init(urls: [URL]) {
        self.urls = urls
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeaderView()
            
            if urls.isEmpty {
                EmptyStateView()
            } else {
                AddedAssetGridView(urls: urls)
            }
        }
        .padding(24)
    }
}

// MARK: - Components

/// 섹션 타이틀 헤더
fileprivate struct SectionHeaderView: View {
    var body: some View {
        Text("추가된 에셋")
            .foregroundStyle(.primary)
            .font(.system(size: 17, weight: .bold))
    }
}

/// 비어있을 때 문구
fileprivate struct EmptyStateView: View {
    var body: some View {
        Text("아직 추가된 에셋이 없어요.")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
    }
}

/// 3열 기본 그리드 래퍼
fileprivate struct AddedAssetGridView: View {
    let urls: [URL]
    
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(urls.enumerated()), id: \.offset) { _, url in
                    AssetThumb(url: url)
                        .frame(width: 96, height: 72)
                }
            }
        }
    }
}

/// URL에서 이미지를 로드해 보여주는 썸네일
fileprivate struct AssetThumb: View {
    let url: URL
    
    var body: some View {
        if let img = loadImage(url) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .clipShape(Rectangle())
        } else {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Methods
    
    /// 파일 URL에서 데이터를 읽어 UIImage로 변환
    /// - Parameter url: 이미지 파일 경로
    /// - Returns: 로드 성공 시 썸네일 이미지, 실패 시 `nil`
    private func loadImage(_ url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Preview

#Preview("AddedAssetsPreview — With Items") {
    let urls: [URL] = [
        "https://url-shortener.me/778S",
        "https://url-shortener.me/779S",
        "https://url-shortener.me/779Q",
        "https://url-shortener.me/778S"
    ].compactMap(URL.init(string:))

    AddedAssetsPreview(urls: urls)
        .frame(width: 380, height: 362)
        .glassBackgroundEffect()
}

#Preview("AddedAssetsPreview — Empty") {
    AddedAssetsPreview(urls: [])
        .frame(width: 380, height: 362)
        .glassBackgroundEffect()
}
