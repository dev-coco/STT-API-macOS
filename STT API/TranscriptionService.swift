import Foundation
import FluidAudio
import AVFoundation

actor TranscriptionService {
    private var asr: AsrManager?
    // 记录模型是否已加载完毕
    private var isInitialized = false
    
    

    // 只有在第一次调用转录或明确要求下载时才执行
    func initializeIfNeeded() async throws {
        if isInitialized { return }
        
        // 下载模型
        let models = try await AsrModels.downloadAndLoad(version: .v3)

        // 使用默认配置初始化 ASR 管理器
        let config = ASRConfig.default
        asr = AsrManager(config: config)
        
        // 加载模型
        try await asr?.initialize(models: models)
        
        isInitialized = true
    }

    // 音频转换文字
    func transcribe(fileURL: URL) async throws -> String {
        try await initializeIfNeeded()
        guard let asr = asr else { throw NSError(domain: "ASR", code: 500) }
        
        print("开始转换音频: \(fileURL.lastPathComponent)")
        // 音频预处理
        let samples = try AudioConverter().resampleAudioFile(fileURL)
        
        // 开始转录
        let result = try await asr.transcribe(samples, source: .system)
        print("转录完成: \(result.text.prefix(50))...")
        
        return result.text
    }
}
