//
//  SoundEntity.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/29/25.
//


import RealityKit
import Foundation
import UIKit

struct SoundEntity {
    
    /// 선형 볼륨(0...1)을 데시벨(dB)로 변환
    /// - Note:
    ///   - 0에 가까운 값은 로그 변환 특성상 -무한대로 향하므로, 하한선(약 -80 dB)로 클램프
    ///   - `gain`은 dB 단위(Double)이며, 1.0 → 0 dB, 0.5 → 약 -6 dB
    /// - Parameter x: 0...1 범위의 선형 볼륨 값. 범위를 벗어나면 내부에서 0...1로 클램프
    /// - Returns: dB 단위의 값(최소 -80 dB로 제한)
    private static func linearToDecibels(_ x: Double) -> RealityKit.Audio.Decibel {
        let clamped = max(0.000_001, min(1.0, x))
        let db: Double = 20.0 * Foundation.log10(clamped)
        return RealityKit.Audio.Decibel(max(db, -80.0))
    }
    
    /// .audio SceneObject와 오디오 Asset으로부터 시각 아이콘 + 오디오 재생이 가능한 엔티티를 생성
    /// - 처리 순서:
    ///   1) 루트 Entity 생성 및 위치/이름 세팅
    ///   2) 썸네일 아이콘(ModelEntity) 생성: 에셋 카탈로그의 `img_soundObject` 텍스처 적용
    ///   3) 오디오 리소스 비동기 로드(visionOS 호환 생성자) 및 루프/볼륨(dB) 설정 → 재생
    ///   4) AudioPlaybackController를 컴포넌트로 보관하고 SceneAudioCoordinator에 등록
    /// - Parameters:
    ///   - sceneObject: .audio 속성을 가진 SceneObject. 위치/이름/초기 볼륨 등을 사용
    ///   - asset: 실제 오디오 파일 URL을 담은 Asset
    ///   - viewMode: 보기 모드 전환을 위한 bool
    /// - Returns: 구성 완료된 루트 Entity. .audio 타입이 아니거나 로드 실패 시 `nil` 반환
    static func create(from sceneObject: SceneObject,
                       with asset: Asset,
                       viewMode: Bool = false
    ) -> ModelEntity? {
        guard case .audio(let audioAttrs) = sceneObject.attributes else {
            print("❌ SoundEntity.create: .audio 타입 아님"); return nil
        }
        
        guard let texture = try? TextureResource.load(named: "img_soundObject") else {
            print("⚠️ SoundEntity.create: img_soundObject 텍스처 로드 실패")
            return nil
        }
        
        let baseWidth: Float = 0.18
        let uiSize = UIImage(named: "img_soundObject")?.size ?? .init(width: 1, height: 1)
        let aspect = uiSize.width > 0 ? (uiSize.height / uiSize.width) : 1.0
        let width: Float  = baseWidth
        let height: Float = baseWidth * Float(aspect)
        
        var unlit = UnlitMaterial(color: .white)
        unlit.color = .init(texture: .init(texture))
        unlit.blending = .transparent(opacity: 1.0)
        
        let mesh = MeshResource.generateBox(width: width, height: height, depth: 0.01)
        let modelEntity = ModelEntity(mesh: mesh, materials: [unlit])
        modelEntity.name = sceneObject.id.uuidString
        // y축 위치를 0 이상으로 제한
        let clampedPosition = SIMD3<Float>(
            sceneObject.position.x,
            max(0, sceneObject.position.y),
            sceneObject.position.z
        )
        modelEntity.position = clampedPosition
        
        modelEntity.collision = CollisionComponent(
            shapes: [.generateBox(width: width, height: height, depth: 0.01)]
        )
        modelEntity.components.set(InputTargetComponent())
        modelEntity.components.set(HoverEffectComponent())
        modelEntity.components.set(BillboardComponent())
        
        Task {
            do {
                var cfg = AudioFileResource.Configuration()
                cfg.shouldLoop = true
                
                let res = try await AudioFileResource(contentsOf: asset.url, configuration: cfg)
                let controller = modelEntity.prepareAudio(res)
                
                modelEntity.components.set(SoundControllerComponent(controller: controller))
                SceneAudioCoordinator.shared.register(entityId: sceneObject.id, controller: controller)
                
                let db = linearToDecibels(Double(audioAttrs.volume))
                SceneAudioCoordinator.shared.setGain(db, for: sceneObject.id)
                
                if audioAttrs.volume > 0 {
                    SceneAudioCoordinator.shared.play(sceneObject.id)
                } else {
                    SceneAudioCoordinator.shared.pause(sceneObject.id) // stop() 대신 pause가 복구에 유리
                }
            } catch {
                print("⚠️ SoundEntity.create: 오디오 로드 실패 - \(error)")
            }
        }
        return modelEntity
    }
}
