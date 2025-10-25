//
//  WaveformProvider.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

import AVFoundation
import Foundation

protocol WaveformProviderProtocol {
    func waveform(url: URL, targetSamples: Int, method: WaveformMethod) async -> [Float]
}

enum WaveformMethod { case peak, rms }

struct WaveformProvider: WaveformProviderProtocol {
    func waveform(url: URL, targetSamples: Int = 120, method: WaveformMethod = .peak) async -> [Float] {
        do {
            return try await Task.detached(priority: .utility) {
                try await makeWaveform(url: url, targetSamples: targetSamples, method: method)
            }.value
        } catch {
            return Array(repeating: 0, count: targetSamples)
        }
    }
    
    /// URL의 오디오에서 0...1 파형을 추출해 길이 `targetSamples`로 다운샘플.
    func makeWaveform(url: URL,
                      targetSamples: Int = 120,
                      method: WaveformMethod = .peak) throws -> [Float] {
        guard targetSamples > 0 else { return [] }
        
        let file = try AVAudioFile(forReading: url)
        let inFormat = file.processingFormat
        let totalFrames = AVAudioFrameCount(file.length)
        
        // 길이 0 파일이면 0으로 채워 반환 (빈 배열 X)
        if totalFrames == 0 { return Array(repeating: 0, count: targetSamples) }
        
        // 출력 포맷: Float32, 비인터리브, 1~2채널
        let outChannels = min(inFormat.channelCount, 2)
        guard let outFormat = AVAudioFormat(standardFormatWithSampleRate: inFormat.sampleRate,
                                            channels: outChannels) else {
            return Array(repeating: 0, count: targetSamples)
        }
        
        let needsConvert = (inFormat != outFormat)
        let converter = needsConvert ? AVAudioConverter(from: inFormat, to: outFormat) : nil
        
        // 다운샘플 버킷
        var peaks  = Array(repeating: Float(0),  count: targetSamples)
        var sums   = Array(repeating: Double(0), count: targetSamples)
        var counts = Array(repeating: Int(0),    count: targetSamples)
        
        // 스트리밍 읽기/변환
        let chunk: AVAudioFrameCount = 4096
        var consumed: AVAudioFramePosition = 0
        
        while consumed < AVAudioFramePosition(totalFrames) {
            let remain = AVAudioFrameCount(AVAudioFramePosition(totalFrames) - consumed)
            let nRead  = min(chunk, remain)
            
            guard let inBuf = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: nRead) else { break }
            inBuf.frameLength = nRead
            try file.read(into: inBuf, frameCount: nRead)
            
            // 변환 필요하면 변환, 아니면 그대로 소스 사용
            let srcBuf: AVAudioPCMBuffer
            if let converter {
                guard let outBuf = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: nRead) else { break }
                var error: NSError?
                converter.convert(to: outBuf, error: &error) { _, outStatus in
                    outStatus.pointee = .haveData
                    return inBuf
                }
                if let error { throw error }
                srcBuf = outBuf
            } else {
                srcBuf = inBuf
            }
            
            guard let ch0 = srcBuf.floatChannelData?[0] else { break }
            let frames = Int(srcBuf.frameLength)
            let ch1 = outChannels > 1 ? srcBuf.floatChannelData?[1] : nil
            
            for i in 0..<frames {
                let a = abs(ch0[i])
                let v: Float
                if let ch1 = ch1 {
                    v = max(a, abs(ch1[i]))
                } else {
                    v = a
                }
                
                let global = Int(consumed) + i
                let bucket = min(targetSamples - 1,
                                 max(0, Int((Double(global) / Double(totalFrames)) * Double(targetSamples))))
                
                switch method {
                case .peak:
                    peaks[bucket] = max(peaks[bucket], v)
                case .rms:
                    sums[bucket] += Double(v * v)
                    counts[bucket] += 1
                }
            }
            
            consumed += AVAudioFramePosition(nRead)
        }
        
        // 결과 생성
        var result: [Float]
        switch method {
        case .peak:
            result = peaks
        case .rms:
            result = zip(sums, counts).map { (sum, c) in
                c > 0 ? Float(sqrt(sum / Double(c))) : 0
            }
        }
        
        // 0...1 정규화 (최대값으로 나눔)
        if let m = result.max(), m > 0 {
            let inv = 1.0 / m
            for i in result.indices { result[i] *= Float(inv) }
        }
        
        // 혹시라도 길이가 어긋나면 맞춰준다
        if result.count != targetSamples {
            if result.count < targetSamples {
                result += Array(repeating: 0, count: targetSamples - result.count)
            } else {
                // 간단 리샘플
                var trimmed = [Float](repeating: 0, count: targetSamples)
                for i in 0..<targetSamples {
                    let t = Double(i) / Double(targetSamples) * Double(result.count - 1)
                    trimmed[i] = result[Int(t.rounded())]
                }
                result = trimmed
            }
        }
        
        return result
    }
}
