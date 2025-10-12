//
//  SubjectExtractError.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/8/25.
//

import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum SubjectExtractError: Error { case noCGImage, noResult, output }

func extractSubjectPNG(from image: UIImage) async throws -> UIImage {
    guard let cg = image.cgImage else { throw SubjectExtractError.noCGImage }

    // 1) 전경 인스턴스 마스크 요청
    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(cgImage: cg, options: [:])
    try handler.perform([request])
    guard let obs = request.results?.first else { throw SubjectExtractError.noResult }

    // 2) 마스크 생성
    let maskCG = try obs.generateScaledMaskForImage(forInstances: obs.allInstances, from: handler)

    // 3) 마스크를 알파로 합성 → 배경 투명
    let ci = CIImage(cgImage: cg)
    let ciMask = CIImage(cgImage: maskCG as! CGImage)

    let f = CIFilter.blendWithAlphaMask()
    f.inputImage = ci
    f.maskImage = ciMask
    f.backgroundImage = CIImage(color: .clear).cropped(to: ci.extent)

    let ctx = CIContext()
    guard let out = f.outputImage,
          let outCG = ctx.createCGImage(out, from: out.extent) else {
        throw SubjectExtractError.output
    }
    return UIImage(cgImage: outCG, scale: image.scale, orientation: image.imageOrientation)
}
