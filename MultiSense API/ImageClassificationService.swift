import Foundation
import Vision
import AppKit

// 图像分类服务
struct ImageClassificationService {
    // 执行图像物体分类识别
    func classifyImage(imageData: Data) async throws -> [ClassificationResult] {
        // 将 Data 转换为 NSImage
        guard let image = NSImage(data: imageData),
              // 从 NSImage 中提取 CGImage
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(
                domain: "Classify",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "无效的图片数据"]
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            // 创建图像分类请求
            let request = VNClassifyImageRequest { request, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    // 没有识别出结果
                    continuation.resume(returning: [])
                    return
                }

                // 处理分类结果
                let results = observations
                    .filter { $0.confidence > 0.05 } // 去掉置信度太低的结果
                    .map {
                        // 转换格式
                        ClassificationResult(
                            identifier: $0.identifier,
                            confidence: $0.confidence
                        )
                    }

                continuation.resume(returning: results)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                // 执行图像分类请求
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
