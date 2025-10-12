//
//  URLImageView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/9/25.
//

import SwiftUI

struct URLImageView: View {
    let url: URL?
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            case .empty:
                ProgressView()
            @unknown default:
                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }
        }
        
    }
}
