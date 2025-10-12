//
//  SubjectLiftDragView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import UIKit
import VisionKit

struct SubjectLiftDragView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        // 이미지 뷰
        let iv = UIImageView(image: image)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        container.addSubview(iv)

        // 컨테이너에 꽉 채우되, 내부에서 aspectFit로 맞춤
        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            iv.topAnchor.constraint(equalTo: container.topAnchor),
            iv.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // 실기기: 피사체 리프트
        #if !targetEnvironment(simulator)
        if #available(iOS 17.0, visionOS 1.0, *) {
            let interaction = ImageAnalysisInteraction()
            interaction.preferredInteractionTypes = [.automatic]
            iv.addInteraction(interaction)
        }
        #endif

        // 폴백 드래그
        let drag = UIDragInteraction(delegate: context.coordinator)
        drag.isEnabled = true
        iv.addInteraction(drag)

        // 보관
        context.coordinator.imageView = iv
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        // 최신 이미지로 갱신
        context.coordinator.imageView?.image = image
    }

    func makeCoordinator() -> Coordinator { Coordinator(image: image) }

    final class Coordinator: NSObject, UIDragInteractionDelegate {
        var image: UIImage
        weak var imageView: UIImageView?
        init(image: UIImage) { self.image = image }

        func dragInteraction(_ interaction: UIDragInteraction,
                             itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            let provider = NSItemProvider(object: image)
            return [UIDragItem(itemProvider: provider)]
        }
    }
}
