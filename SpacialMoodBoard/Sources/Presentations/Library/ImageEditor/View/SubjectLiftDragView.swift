//
//  SubjectLiftDragView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import VisionKit

/// UIKit 기반의 `UIImageView`에 아래기능을 붙여 SwiftUI에서 재사용할 수 있게 한 래퍼 뷰
/// - iOS 17/visionOS 1.0 이상: 피사체 리프트(Subject Lift) 상호작용(`ImageAnalysisInteraction`)
/// - 폴백: 드래그 앤 드롭(UIDragInteraction)
///
/// 사용 방법:
/// ```swift
/// SubjectLiftDragView(image: someUIImage)
///     .frame(width: 400, height: 300)
/// ```
///
/// 주의:
/// - 시뮬레이터에선 VisionKit 상호작용이 비활성화
/// - 피사체 리프트는 iOS 17 / visionOS 1.0 이상에서만 가능
struct SubjectLiftDragView: UIViewRepresentable {
    
    // MARK: - Properties
    
    private let image: UIImage
    
    // MARK: - Init
    
    /// init
    /// - Parameter image: UIImage
    init(image: UIImage) {
        self.image = image
    }
    
    // MARK: - Methods
    
    
    /// UIKit 측 루트 `UIView` 생성
    /// - Parameter context: SwiftUI가 제공하는 컨텍스트(코디네이터 접근 등에 사용)
    /// - Returns: 피사체 리프트/드래그 상호작용이 설정된 컨테이너 뷰
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        
        let iv = UIImageView(image: image)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        container.addSubview(iv)
        
        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            iv.topAnchor.constraint(equalTo: container.topAnchor),
            iv.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
#if !targetEnvironment(simulator)
        if #available(iOS 17.0, visionOS 1.0, *) {
            let interaction = ImageAnalysisInteraction()
            interaction.preferredInteractionTypes = [.imageSubject]
            iv.addInteraction(interaction)
            
            context.coordinator.imageView = iv
            context.coordinator.interaction = interaction
            context.coordinator.runSubjectLiftAnalysis(for: image)
        }
#endif
        
        let drag = UIDragInteraction(delegate: context.coordinator)
        drag.isEnabled = true
        iv.addInteraction(drag)
        
        return container
    }
    
    /// SwiftUI 상태 업데이트에 따라 UIKit 뷰 갱신
    /// - Parameters:
    ///   - container: `makeUIView`에서 생성한 컨테이너 뷰
    ///   - context: 컨텍스트(코디네이터 등)
    func updateUIView(_ container: UIView, context: Context) {
        context.coordinator.imageView?.image = image
#if !targetEnvironment(simulator)
        if #available(iOS 17.0, visionOS 1.0, *) {
            context.coordinator.runSubjectLiftAnalysis(for: image)
        }
#endif
    }
    
    /// 코디네이터를 생성, UIKit 델리게이트/상태를 보관
    /// - Returns: 코디네이터 반환
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    
    // MARK: - class Coordinator
    
    /// UIKit 상호작용(분석/드래그) 델리게이트와 경량 상태를 관리합니다.
    final class Coordinator: NSObject, UIDragInteractionDelegate {
        weak var imageView: UIImageView?
        weak var interaction: ImageAnalysisInteraction?
        private var lastImageHash: Int?
        
        /// 피사체 리프트를 위한 이미지 분석을 수행하고 결과를 상호작용에 연결
        /// - Parameter image: 분석할 이미지
        @MainActor
        func runSubjectLiftAnalysis(for image: UIImage) {
            guard #available(iOS 17.0, visionOS 1.0, *) else { return }
            let h = image.hash
            if lastImageHash == h { return }
            lastImageHash = h
            
            let analyzer = ImageAnalyzer()
            let config = ImageAnalyzer.Configuration([])
            
            Task {
                do {
                    let analysis = try await analyzer.analyze(image, configuration: config)
                    interaction?.analysis = analysis
                } catch {
                    print("Image analysis failed:", error)
                }
            }
        }
        
        /// 드래그 시작 시 제공할 아이템(폴백 드래그용)
        /// - Parameters:
        ///   - interaction: 드래그 상호작용
        ///   - session: 드래그 세션
        /// - Returns: 드래그할 `UIDragItem` 배열(여기선 이미지 1개)
        func dragInteraction(_ interaction: UIDragInteraction,
                             itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            guard let img = imageView?.image else { return [] }
            return [UIDragItem(itemProvider: NSItemProvider(object: img))]
        }
    }
}
