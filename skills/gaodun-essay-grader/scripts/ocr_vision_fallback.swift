// Apple Vision OCR 兜底脚本（zh-Hans）
//
// 用途：仅当 Read 工具直读图片效果差（字迹潦草/图片模糊）时使用。
// 实测手写体准确率明显不如模型直读，不要作为首选。
//
// 用法：swift ocr_vision_fallback.swift <图片路径>

import Foundation
import Vision
import AppKit

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("usage: ocr_vision_fallback.swift <image>\n".data(using: .utf8)!)
    exit(1)
}

guard let img = NSImage(contentsOfFile: CommandLine.arguments[1]),
      let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write("cannot load image\n".data(using: .utf8)!)
    exit(1)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["zh-Hans", "en-US"]
request.usesLanguageCorrection = false

do {
    try VNImageRequestHandler(cgImage: cg, options: [:]).perform([request])
    guard let obs = request.results else { exit(0) }
    // 大致按「从上到下、从左到右」排序
    let sorted = obs.sorted { a, b in
        let ay = a.boundingBox.origin.y, by = b.boundingBox.origin.y
        if abs(ay - by) > 0.01 { return ay > by }
        return a.boundingBox.origin.x < b.boundingBox.origin.x
    }
    for o in sorted {
        if let top = o.topCandidates(1).first { print(top.string) }
    }
} catch {
    FileHandle.standardError.write("OCR failed: \(error)\n".data(using: .utf8)!)
    exit(1)
}
