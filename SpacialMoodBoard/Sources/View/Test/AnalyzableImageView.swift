//
//  AnalyzableImageView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/8/25.
//

import SwiftUI
import VisionKit

struct AnalyzableImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true

        let interaction = ImageAnalysisInteraction()
        iv.addInteraction(interaction)

        Task {
            let analyzer = ImageAnalyzer()
            // 구성에는 imageSubject를 넣지 않습니다
            let config = ImageAnalyzer.Configuration([.visualLookUp, .text, .machineReadableCode])
            if let analysis = try? await analyzer.analyze(image, configuration: config) {
                await MainActor.run {
                    interaction.analysis = analysis
                    // 분석을 세팅한 뒤 원하는 상호작용 타입 지정
                    interaction.preferredInteractionTypes = [.automatic] // 또는 [.imageSubject]
                }
            }
        }
        return iv
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        guard uiView.image !== image else { return }
        uiView.image = image
        if let interaction = uiView.interactions.compactMap({ $0 as? ImageAnalysisInteraction }).first {
            interaction.analysis = nil
            interaction.preferredInteractionTypes = []
            Task {
                let analyzer = ImageAnalyzer()
                let config = ImageAnalyzer.Configuration([.visualLookUp, .text, .machineReadableCode])
                if let analysis = try? await analyzer.analyze(image, configuration: config) {
                    await MainActor.run {
                        interaction.analysis = analysis
                        interaction.preferredInteractionTypes = [.automatic]
                    }
                }
            }
        }
    }
}
