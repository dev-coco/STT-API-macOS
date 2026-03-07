import Foundation
import Vision
import AppKit

// 图片识别文字服务
struct OCRService {
    // 执行 OCR 文字识别
    func performOCR(imageData: Data, languages: [String], keepLineBreaks: Bool) async throws -> String {
        // 将 Data 转换为 NSImage
        guard let image = NSImage(data: imageData),
              // 从 NSImage 中提取 CGImage
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "OCR", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的图片数据"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            // 创建文字识别请求
            let request = VNRecognizeTextRequest { request, error in

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    // 没有识别出结果
                    continuation.resume(returning: "")
                    return
                }

                // 只取最可能的识别结果
                let maximumCandidates = 1
                
                // 用于存储识别出来的文本片段
                var recognizedStrings = [String]()

                // 遍历所有检测到的文本区域
                for observation in observations {
                    // 返回置信度最高的结果
                    if let candidate = observation.topCandidates(maximumCandidates).first {
                        // 识别出的文字内容
                        recognizedStrings.append(candidate.string)
                    }
                }

                // 根据参数决定是保留换行还是用空格连接
                let separator = keepLineBreaks ? "\n" : " "
                let resultText = recognizedStrings.joined(separator: separator)
                continuation.resume(returning: resultText)
            }

            // 设置识别参数
            request.recognitionLevel = .accurate // 高精度模式
            request.recognitionLanguages = languages // 识别语言
            request.usesLanguageCorrection = true // 启用语言纠错

            // 执行图像识别任务
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                options: [:]
            )
            
            do {
                // 执行 OCR 请求
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
