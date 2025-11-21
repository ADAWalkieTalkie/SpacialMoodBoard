//
//  LibraryImageTabGridView.swift
//  Glayer
//
//  Created by jeongminji on 11/20/25.
//

import SwiftUI

struct LibraryImageTabGridView: View {
    let assets: [Asset]
    let onAdded: () -> Void
    
    @Environment(SceneViewModel.self) private var sceneViewModel
    @Environment(LibraryViewModel.self) private var viewModel
    
    private let channelOrder: [ImageChannel] = [
        .background,
        .furniture,
        .floor,
        .electronic,
        .animal,
        .plant
    ]
    
    var body: some View {
        let grouped: [ImageChannel: [Asset]] =
        Dictionary(grouping: assets) { ($0.image?.channel) ?? .background }
        
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.originImageFilter == .userOnly {
                    let columns = [GridItem(.adaptive(minimum: 220, maximum: 272), spacing: 32)]
                    
                    LazyVGrid(columns: columns, spacing: 36) {
                        ForEach(assets) { asset in
                            LibraryImageItemView(asset: asset, allowRename: true)
                                .frame(width: 220, height: 272)
                                .hoverEffect(.highlight)
                                .simultaneousGesture(
                                    TapGesture().onEnded {
                                        do {
                                            _ = try sceneViewModel.addImageObject(from: asset)
                                            onAdded()
                                        } catch { }
                                    }
                                )
                        }
                    }
                    
                } else {
                    ForEach(Array(channelOrder.enumerated()), id: \.element) { index, ch in
                        let items: [Asset] = grouped[ch] ?? []
                        if !items.isEmpty {
                            VStack(spacing: 0) {
                                DisclosureToggleButton(
                                    title: ch.title,
                                    isExpanded: viewModel.isExpanded(ch),
                                    action: { viewModel.toggleChannel(ch) }
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if viewModel.isExpanded(ch) {
                                    let columns = [GridItem(.adaptive(minimum: 220, maximum: 272), spacing: 32)]
                                    
                                    LazyVGrid(columns: columns, spacing: 36) {
                                        ForEach(items) { asset in
                                            LibraryImageItemView(asset: asset, allowRename: false)
                                                .frame(width: 220, height: 272)
                                                .hoverEffect(.highlight)
                                                .simultaneousGesture(
                                                    TapGesture().onEnded {
                                                        do {
                                                            _ = try sceneViewModel.addImageObject(from: asset)
                                                            onAdded()
                                                        } catch { }
                                                    }
                                                )
                                        }
                                    }
                                    .padding(.top, 16)
                                    .animation(
                                        .easeInOut(duration: 0.25),
                                        value: viewModel.isExpanded(ch)
                                    )
                                }
                            }
                            .padding(.top, index == 0 ? 0 : 24)
                        }
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 40)
        }
    }
}
