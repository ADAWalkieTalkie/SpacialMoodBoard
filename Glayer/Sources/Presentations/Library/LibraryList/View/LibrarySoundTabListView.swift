//
//  LibrarySoundTabListView.swift
//  Glayer
//
//  Created by jeongminji on 11/20/25.
//

import SwiftUI

struct LibrarySoundTabListView: View {
    let assets: [Asset]
    let onAdded: () -> Void
    @Environment(SceneViewModel.self) private var sceneViewModel
    @Environment(LibraryViewModel.self) private var viewModel
    
    private let channelOrder: [SoundChannel] = [.foley, .ambient]
    
    var body: some View {
        let grouped: [SoundChannel: [Asset]] =
        Dictionary(grouping: assets) { ($0.sound?.channel) ?? .ambient }
        
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.originSoundFilter == .userOnly {
                    LazyVStack(spacing: 12) {
                        ForEach(assets) { asset in
                            LibrarySoundItemView(
                                asset: asset,
                                allowRename: true
                            ) {
                                do {
                                    _ = try sceneViewModel.addSoundObject(from: asset)
                                    onAdded()
                                } catch { }
                            }
                            .frame(height: 56)
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
                                    LazyVStack(spacing: 12) {
                                        ForEach(items) { asset in
                                            LibrarySoundItemView(
                                                asset: asset,
                                                allowRename: false
                                            ) {
                                                do {
                                                    _ = try sceneViewModel.addSoundObject(from: asset)
                                                    onAdded()
                                                } catch { }
                                            }
                                            .frame(height: 56)
                                        }
                                    }
                                    .animation(.easeInOut(duration: 0.25), value: viewModel.isExpanded(ch))
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
