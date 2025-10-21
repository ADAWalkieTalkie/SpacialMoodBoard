//
//  WaveformScrubberView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

import SwiftUI

/// 고정 파형 위에서 재생 진행(플레이헤드)과 스크럽을 제공하는 뷰
/// - `samples`: 0...1 로 정규화된 파형(막대) 값 배열
/// - `progress`: 0...1 재생 진행도 바인딩
/// - `onScrubStart`: 스크럽 시작 시 호출(선택)
/// - `onScrubEnd`: 스크럽 종료 시 최종 진행도와 함께 호출(선택)
struct WaveformScrubberView: View {

    // MARK: - Properties

    private let samples: [Float]
    @Binding private var progress: Double
    private let onScrubStart: (() -> Void)?
    private let onScrubEnd: ((Double) -> Void)?

    @Environment(\.displayScale) private var scale

    // MARK: - Init

    /// Init
    /// - Parameters:
    ///   - samples: 0...1 로 정규화된 파형 샘플
    ///   - progress: 0...1 진행도 바인딩
    ///   - onScrubStart: 드래그(스크럽) 시작 시 콜백
    ///   - onScrubEnd: 드래그(스크럽) 끝에서 최종 진행도 콜백
    init(
        samples: [Float],
        progress: Binding<Double>,
        onScrubStart: (() -> Void)? = nil,
        onScrubEnd: ((Double) -> Void)? = nil
    ) {
        self.samples = samples
        self._progress = progress
        self.onScrubStart = onScrubStart
        self.onScrubEnd = onScrubEnd
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let w = max(1, geo.size.width)
            let h = max(1, geo.size.height)
            let count = max(1, samples.count)

            let spacing: CGFloat = 3
            let rawBarW = (w - CGFloat(count - 1) * spacing) / CGFloat(count)
            let barW = snap(max(1, rawBarW), scale: scale)
            let step = snap(barW + spacing, scale: scale)
            let headX = snap(CGFloat(progress) * w, scale: scale)

            ZStack(alignment: .leading) {
                WaveformBars(
                    samples: samples,
                    width: w, height: h,
                    barWidth: barW, step: step,
                    color: .white.opacity(0.28),
                    scale: scale
                )

                WaveformBars(
                    samples: samples,
                    width: w, height: h,
                    barWidth: barW, step: step,
                    color: .white,
                    scale: scale
                )
                .mask(
                    Rectangle()
                        .frame(width: headX)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )
                
                Playhead(height: h, x: headX, scale: scale)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        onScrubStart?()
                        let f = max(0, min(1, g.location.x / w))
                        progress = f
                    }
                    .onEnded { g in
                        let f = max(0, min(1, g.location.x / w))
                        progress = f
                        onScrubEnd?(f)
                    }
            )
        }
    }
    
    // MARK: - SubView
    
    /// 공용 막대 렌더러(배경/진행 모두 사용)
    struct WaveformBars: View {
        let samples: [Float]
        let width: CGFloat
        let height: CGFloat
        let barWidth: CGFloat
        let step: CGFloat
        let color: Color
        let scale: CGFloat

        var body: some View {
            Canvas(opaque: false, rendersAsynchronously: true) { ctx, _ in
                var x: CGFloat = 0
                let count = samples.count
                let minBarH: CGFloat = 2
                let verticalScale: CGFloat = 0.9

                for i in 0..<count {
                    let amp = max(0.06, min(1, CGFloat(samples[i])))
                    let barH = max(minBarH, amp * height * verticalScale)
                    let rect = CGRect(
                        x: x,
                        y: (height - barH) / 2,
                        width: barWidth,
                        height: barH
                    )
                    ctx.fill(
                        Path(roundedRect: rect, cornerRadius: barWidth / 2),
                        with: .color(color)
                    )
                    x += step
                    if x > width { break }
                }
            }
        }
    }

    /// 플레이헤드(재생 지시선)
    struct Playhead: View {
        let height: CGFloat
        let x: CGFloat
        let scale: CGFloat

        var body: some View {
            Rectangle()
                .fill(.white)
                .frame(width: snap(2, scale: scale), height: height * 0.95)
                .offset(x: x - snap(1, scale: scale))
                .shadow(radius: 1)
        }

        private func snap(_ v: CGFloat, scale: CGFloat) -> CGFloat {
            (v * scale).rounded(.toNearestOrAwayFromZero) / scale
        }
    }

    // MARK: - Methods

    /// 디스플레이 스케일 기준 픽셀 스냅 → 가장자리 블러/삐져나옴 방지
    private func snap(_ v: CGFloat, scale: CGFloat) -> CGFloat {
        (v * scale).rounded(.toNearestOrAwayFromZero) / scale
    }
}
