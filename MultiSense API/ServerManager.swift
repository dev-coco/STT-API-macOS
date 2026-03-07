import Vapor
import SwiftUI
import Combine

// 转录接口返回的 JSON 结构
struct TranscribeResponse: Content {
    let text: String
}

// 状态响应结构
struct ResponseStatus: Content {
    let status: String
    let transcribe: Bool
    let ocr: Bool
    let classify: Bool
}

// 单个识别分类结果
struct ClassificationResult: Content {
    let identifier: String
    let confidence: Float
}

// 分类接口的标准响应
struct ClassifyResponse: Content {
    let labels: [ClassificationResult]
}

@MainActor
class ServerManager: ObservableObject {
    // 软件显示状态的文本
    @Published var status = String(localized: "systemReady")
    // 服务是否正在运行的状态
    @Published var isRunning = false
    // 模型下载进度
    @Published var downloadProgress: Double = 0.0
    // 正在下载模型的状态
    @Published var isDownloading = false
    // 模型是否已准备好
    @Published var isModelReady = false
    // 默认端口
    @Published var port: String = "1643"
    
    private var vApp: Application?
    // 异步服务器任务
    private var serverTask: Task<Void, Never>?
    // 进度监听定时器
    private var progressTimer: Timer?
    // 执行转录的底层 SDK 服务
    let service = TranscriptionService()
    
    // 图片识别文字服务
    let ocrService = OCRService()
    // 图片识别分类服务
    let classificationService = ImageClassificationService()
    
    // 模型文件存储的完整路径
    private var modelPath: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Application Support/FluidAudio/Models/v3")
    }
    
    // 模型预计 483 MB
    private let totalModelSize: Double = 483 * 1024 * 1024

    // 检查模型是否已下载
    func checkModelExists() {
        isModelReady = FileManager.default.fileExists(atPath: modelPath.path)
        if isModelReady {
            status = String(localized: "modelCached")
            downloadProgress = 1.0
        }
    }

    // 监控目录下的文件大小，计算已下载的字节数
    // 因为从 SDK 下载无法获得进度
    private func getDownloadedSize(at url: URL) -> Double {
        let fileManager = FileManager.default
        var totalSize: Double = 0
        
        // 检查目标路径文件大小
        if let size = try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64 {
            totalSize += Double(size)
        }
        
        // 扫描统计目录，统计所有文件总和
        let parentDir = url.deletingLastPathComponent()
        if let contents = try? fileManager.contentsOfDirectory(at: parentDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in contents {
                // 监控所有正在增长的文件
                if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Double(size)
                }
            }
        }
        
        // 扫描临时目录
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        if let tempContents = try? fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in tempContents {
                // 过滤掉太小的文件
                if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 10 * 1024 * 1024 {
                    totalSize += Double(size)
                }
            }
        }
        
        return totalSize
    }
    
    // 下载模型
    func downloadModel() async {
        checkModelExists()
        if isModelReady { return }
        
        isDownloading = true
        status = String(localized: "connectingServer")
        downloadProgress = 0.0
        
        // 启动定时器更新进度
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                let currentSize = self.getDownloadedSize(at: self.modelPath)
                let progress = min(currentSize / self.totalModelSize, 0.98)
                
                if progress > self.downloadProgress {
                    self.downloadProgress = progress
//                    self.status = "正在下载资源 (\(Int(progress * 100))%)"
                    self.status = String(format: NSLocalizedString("downloadingProgress", comment: ""), Int(progress * 100))
                } else if progress > 0 {
                    self.status = String(localized: "downloading")
                }
            }
        }
        
        do {
            // 调用 SDK 下载
            try await service.initializeIfNeeded()
            progressTimer?.invalidate()
            self.isModelReady = true
            self.downloadProgress = 1.0
            status = String(localized: "modelLoaded")
        } catch {
            progressTimer?.invalidate()
            status = String(localized: "downloadInterrupted")
            downloadProgress = 0
        }
        isDownloading = false
    }

    // 启动 API 服务
    func start() {
        guard !isRunning else { return }
        let portInt = Int(port) ?? 1643
        status = String(localized: "serviceStarting")
        
        serverTask = Task {
            do {
                // 初始化 Vapor Application
                let app = try await Application.make(.detect())
                self.vApp = app
                
                // 配置参数
                app.routes.defaultMaxBodySize = "5gb" // 最大文件限制
                app.http.server.configuration.hostname = "127.0.0.1"
                app.http.server.configuration.port = portInt
                
                // GET /
                // 检查服务与功能状态
                app.get { req async -> ResponseStatus in
                    
                    // 查询 ASR 是否已初始化
                    let asrLoaded = await self.service.getIsInitialized()
                    return ResponseStatus(
                        status: "success",
                        transcribe: asrLoaded,
                        ocr: true,
                        classify: true
                    )
                }
                
                // POST /transcribe
                // 语音转文字
                app.post("transcribe") { req -> TranscribeResponse in
                    struct TranscribeRequest: Content {
                        var audio: File // 音频 Blob 数据
                    }
                    
                    let body = try req.content.decode(TranscribeRequest.self)
                    
                    // 将上传的二进制流写入临时文件给底层模型读取
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".tmp")
                    try Data(body.audio.data.readableBytesView).write(to: tempURL)
                    
                    // 删除临时文件
                    defer { try? FileManager.default.removeItem(at: tempURL) }
                    
                    // 执行语音识别
                    let text = try await self.service.transcribe(fileURL: tempURL)

                    return TranscribeResponse(text: text)
                }
                
                
                // POST /ocr
                // 图片文字识别
                app.post("ocr") { req -> TranscribeResponse in
                    struct OCRRequest: Content {
                        var image: File // 图片 Blob 数据
                        var language: String? // 逗号分隔语言
                        var lineBreak: Bool? // 是否保留换行
                    }
                    
                    let body = try req.content.decode(OCRRequest.self)
                    
                    // 解析语言参数
                    let langs = body.language?.components(separatedBy: ",") ?? ["zh-Hans", "en-US"]
                    // 是否保留换行
                    let keepLineBreaks = body.lineBreak ?? true
                    
                    // 执行 OCR 处理
                    let text = try await self.ocrService.performOCR(
                        imageData: Data(body.image.data.readableBytesView),
                        languages: langs,
                        keepLineBreaks: keepLineBreaks
                    )
                    
                    return TranscribeResponse(text: text)
                }
                
                // POST /classify
                // 图像物体识别
                app.post("classify") { req async throws -> ClassifyResponse in
                    struct ClassifyRequest: Content {
                        var image: File // 接收名为 image 的文件对象
                    }
                    
                    let body = try req.content.decode(ClassifyRequest.self)
                    
                    // 调用分类服务
                    let results = try await self.classificationService.classifyImage(
                        imageData: Data(body.image.data.readableBytesView)
                    )
                    
                    return ClassifyResponse(labels: results)
                }
                
                
//                self.status = "API 运行中，端口: \(portInt)"
                self.status = String(format: NSLocalizedString("apiRunning", comment: ""), portInt)
                self.isRunning = true
                
                // 启动服务
                try await app.execute()
            } catch {
//                self.status = "启动失败: \(error.localizedDescription)"
                self.status = String(format: NSLocalizedString("startFailed", comment: ""), error.localizedDescription)
                self.isRunning = false
            }
        }
    }

    // 停止 API 服务
    func stop() {
        guard let app = vApp else { return }
        status = String(localized: "serviceStopping")
        Task {
            try? await app.asyncShutdown()
            self.serverTask?.cancel()
            self.vApp = nil
            self.isRunning = false
            self.status = String(localized: "serviceStopped")
        }
    }

    // 打开模型文件夹
    func openModelDirectory() {
        let path = modelPath.deletingLastPathComponent()
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path.path)
    }
}
