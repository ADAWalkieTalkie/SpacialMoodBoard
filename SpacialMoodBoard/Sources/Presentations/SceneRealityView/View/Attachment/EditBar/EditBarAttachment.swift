import SwiftUI

struct EditBarAttachment: View {
    
    // MARK: - Properties
    
    private let objectId: UUID
    private let objectType: AssetType
    
    private let onDuplicate: (() -> Void)?
    private let onCrop: (() -> Void)?
    private let onVolumeChange: ((Double) -> Void)?
    private let onDelete: () -> Void
    
    @State private var volume: Double
    @State private var isMuted: Bool = false
    @State private var lastNonZeroVolume: Double = 1.0
    
    // MARK: - Init
    
    /// init
    /// - Parameters:
    ///   - objectId: 편집 대상 객체의 고유 식별자(UUID)
    ///   - objectType: 객체의 유형(예: 이미지 또는 사운드)
    ///   - initialVolume: 사운드 객체일 경우 초기 볼륨 값(0~1)
    ///   - onVolumeChange: 볼륨이 변경될 때 호출되는 콜백(사운드 전용)
    ///   - onDuplicate: 객체 복제 버튼 탭 시 호출되는 콜백
    ///   - onCrop: 이미지 크롭 버튼 탭 시 호출되는 콜백
    ///   - onDelete: 객체 삭제 버튼 탭 시 호출되는 콜백
    init(
        objectId: UUID,
        objectType: AssetType,
        initialVolume: Double = 1.0,
        onVolumeChange: ((Double) -> Void)? = nil,
        onDuplicate: (() -> Void)? = nil,
        onCrop: (() -> Void)? = nil,
        onDelete: @escaping () -> Void
    ) {
        self.objectId = objectId
        self.objectType = objectType
        self._volume = State(initialValue: min(max(initialVolume, 0.0), 1.0))
        self.onVolumeChange = onVolumeChange
        self.onDuplicate = onDuplicate
        self.onCrop = onCrop
        self.onDelete = onDelete
        self._lastNonZeroVolume = State(initialValue: initialVolume > 0 ? initialVolume : 1.0)
        self._isMuted = State(initialValue: initialVolume == 0)
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: objectType == .image ? 12 : 4) {
            switch objectType {
            case .image:
                // 크롭 버튼
                if let onCrop {
                    EditBarAttachmentButton(systemName: "crop", action: onCrop)
                        .accessibilityLabel("Crop")
                }
                // 복사 버튼
                if let onDuplicate {
                    EditBarAttachmentButton(systemName: "doc.on.doc", action: onDuplicate)
                        .accessibilityLabel("Duplicate")
                }
                
            case .sound:
                EditBarAttachmentButton(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                    toggleMute()
                }
                .accessibilityLabel(isMuted ? "Unmute" : "Mute")
                
                CapsuleVolumeSlider(value: Binding(
                    get: { volume },
                    set: { newValue in
                        volume = newValue
                        if newValue > 0 {
                            lastNonZeroVolume = newValue
                            isMuted = false
                        } else {
                            isMuted = true
                        }
                        onVolumeChange?(newValue)
                    }
                ))
                .frame(width: 80)
                .accessibilityLabel("Volume")
            }
            
            // 공통: 삭제
            EditBarAttachmentButton(systemName: "trash", action: onDelete)
                .accessibilityLabel("Delete")
        }
        .padding(12)
        .background(
            Capsule().fill(.ultraThinMaterial)
        )
        .glassBackgroundEffect()
    }
    
    // MARK: - Methods
    
    private func toggleMute() {
        if isMuted {
            let restore = max(lastNonZeroVolume, 0.1)
            volume = restore
            isMuted = false
            onVolumeChange?(restore)
        } else {
            lastNonZeroVolume = volume > 0 ? volume : lastNonZeroVolume
            volume = 0
            isMuted = true
            onVolumeChange?(0)
        }
    }
}

#Preview {
    EditBarAttachment(
        objectId: UUID(),
        objectType: .image,
        onDuplicate: { print("복사") },
        onCrop: { print("크롭") },
        onDelete: { print("삭제") }
    )
}
