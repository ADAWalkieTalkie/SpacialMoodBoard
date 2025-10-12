//
//  LibraryItemView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/9/25.
//

import SwiftUI

/// 라이브러리 항목(썸네일 + 텍스트 메타)을 행(.row) 또는 카드(.card) 레이아웃으로 렌더링하는 뷰
struct LibraryItemView: View {
    
    // MARK: - Properties
    
    private let imageURL: URL?
    private let title: String
    private let description: String
    private let layout: LibraryItemLayout
    
    // MARK: - Init
    
    /// Init
    /// - Parameters:
    ///   - imageURL: 표시할 이미지의 URL(없으면 플레이스홀더를 표시)
    ///   - title: 항목 제목
    ///   - description: 보조 설명 또는 생성 일시 문자열
    ///   - layout: 표시 레이아웃(.row 또는 .card)
    init(imageURL: URL?, title: String, description: String, layout: LibraryItemLayout) {
        self.imageURL = imageURL
        self.title = title
        self.description = description
        self.layout = layout
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch layout {
            case .row:
                HStack(alignment: .center, spacing: 24) {
                    thumbImage()
                    
                    Text(title).font(.system(size: 20, weight: .bold))
                    
                    Spacer()
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .padding(.trailing, 20)
                
            case .card:
                VStack(alignment: .leading, spacing: 12) {
                    thumbImage()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 20, weight: .bold))
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Methods
    
    /// 공통 썸네일
    /// 1:1 비율을 유지하며 컨테이너 크기에 맞춰 표시
    /// - Returns: 썸네일 이미지 뷰(로딩/실패 플레이스홀더 포함).
    @ViewBuilder
    private func thumbImage() -> some View {
        URLImageView(url: imageURL)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Previews

#Preview {
    VStack {
        LibraryItemView(
            imageURL: URL(string: "https://i.ibb.co/0yhHJbfK/image-23.png"),
            title: "Astronaut",
            description: "2025.10.6 PM 4:30",
            layout: .row
        )
        .frame(width: 529, height: 90)
        .padding()
        
        LibraryItemView(
            imageURL: URL(string: "https://i.ibb.co/0yhHJbfK/image-23.png"),
            title: "Astronaut",
            description: "2025.10.6 PM 4:30",
            layout: .card
        )
        .frame(width: 220, height: 272)
        .padding()
    }
}
