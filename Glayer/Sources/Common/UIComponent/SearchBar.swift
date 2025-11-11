//
//  SearchBar.swift
//  Glayer
//
//  Created by jeongminji on 10/9/25.
//

import SwiftUI
import UIKit

final class CircularSearchBar: UISearchBar {
    private var didObserveSubviews = false
    private let desiredCornerRadius: CGFloat = 22
    private var observedLayers = NSHashTable<CALayer>.weakObjects()

    deinit {
        for obj in observedLayers.allObjects {
            obj.removeObserver(self, forKeyPath: "cornerRadius")
        }
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        guard !didObserveSubviews else { return }
        didObserveSubviews = true
        observeSubviews(self)
        hideHairline(self)
        searchBarStyle = .minimal
    }

    private func observeSubviews(_ view: UIView) {
        if !observedLayers.contains(view.layer) {
            view.layer.addObserver(self, forKeyPath: "cornerRadius", options: [.new], context: nil)
            observedLayers.add(view.layer)
        }
        view.subviews.forEach { observeSubviews($0) }
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "cornerRadius", let layer = object as? CALayer else { return }
        if layer.cornerRadius != desiredCornerRadius { layer.cornerRadius = desiredCornerRadius }
    }

    private func hideHairline(_ view: UIView) {
        if let iv = view as? UIImageView { iv.alpha = 0 }
        view.subviews.forEach { hideHairline($0) }
    }
}

struct VisionSearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "Search"
    var onSubmit: () -> Void = {}

    func makeUIView(context: Context) -> CircularSearchBar {
        let sb = CircularSearchBar()
        sb.placeholder = placeholder
        sb.delegate = context.coordinator
        sb.enablesReturnKeyAutomatically = true
        sb.returnKeyType = .search
        return sb
    }
    
    func updateUIView(_ uiView: CircularSearchBar, context: Context) {
        if uiView.text != text { uiView.text = text }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UISearchBarDelegate {
        var parent: VisionSearchBar
        init(_ p: VisionSearchBar) { parent = p }
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { parent.text = searchText }
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { parent.onSubmit(); searchBar.resignFirstResponder() }
    }
}

struct CenteredVisionSearchBar: View {
    @Binding var text: String
    var placeholder = "Search"
    var onSubmit: () -> Void = {}
    
    var body: some View {
        VisionSearchBar(text: $text, placeholder: placeholder, onSubmit: onSubmit)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    @Previewable @State var searchText = ""
    
    CenteredVisionSearchBar(text: $searchText)
        .glassBackgroundEffect()
}
