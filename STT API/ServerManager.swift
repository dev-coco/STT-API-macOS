import Vapor
import SwiftUI
import Combine

// 定义输出的 JSON 结构，放在类外部以确保作用域全局可见
struct TranscribeResponse: Content {
    let text: String
}

@MainActor
class ServerManager: ObservableObject {
    @Published var status = "系统准备就绪"
    @Published var isRunning = false
    @Published var downloadProgress: Double = 0.0
    @Published var isDownloading = false
    @Published var isModelReady = false
    @Published var port: String = "1643"
    
    private var vApp: Application?
    // 异步服务器任务
    private var serverTask: Task<Void, Never>?
    // 进度监听定时器
    private var progressTimer: Timer?
    // 实际执行转录的底层 SDK 服务
    let service = TranscriptionService()
    
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
            status = "模型已缓存"
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
        status = "正在连接服务器..."
        downloadProgress = 0.0
        
        // 启动定时器更新进度
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                let currentSize = self.getDownloadedSize(at: self.modelPath)
                let progress = min(currentSize / self.totalModelSize, 0.98)
                
                if progress > self.downloadProgress {
                    self.downloadProgress = progress
                    self.status = "正在下载资源 (\(Int(progress * 100))%)"
                } else if progress > 0 {
                    self.status = "正在下载..."
                }
            }
        }
        
        do {
            // 调用 SDK 下载
            try await service.initializeIfNeeded()
            progressTimer?.invalidate()
            self.isModelReady = true
            self.downloadProgress = 1.0
            status = "模型加载完成"
        } catch {
            progressTimer?.invalidate()
            status = "下载中断"
            downloadProgress = 0
        }
        isDownloading = false
    }

    // 启动 API 服务
    func start() {
        guard !isRunning && !isDownloading else { return }
        let portInt = Int(port) ?? 1643
        status = "正在加载引擎..."
        
        serverTask = Task {
            do {
                // 初始化 Vapor Application
                let app = try await Application.make(.detect())
                self.vApp = app
                
                // 配置参数
                app.routes.defaultMaxBodySize = "5gb" // 最大文件限制
                app.http.server.configuration.hostname = "127.0.0.1"
                app.http.server.configuration.port = portInt
                
                // 定义路由：POST /transcribe
                app.post("transcribe") { req -> TranscribeResponse in
                    struct TranscribeRequest: Content {
                        var audio: File // 音频 Blob 数据
                        var language: String? // 可选语言参数
                    }
                    
                    let body = try req.content.decode(TranscribeRequest.self)
                    
                    // 将上传的二进制流写入临时文件给底层模型读取
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".tmp")
                    try Data(body.audio.data.readableBytesView).write(to: tempURL)
                    
                    // 删除临时文件
                    defer { try? FileManager.default.removeItem(at: tempURL) }
                    
                    // 调用核心引擎进行转录
                    let text = try await self.service.transcribe(fileURL: tempURL)

                    return TranscribeResponse(text: text)
                }
                
                self.status = "API 运行中，端口: \(portInt)"
                self.isRunning = true
                
                // 启动服务
                try await app.execute()
            } catch {
                self.status = "启动失败: \(error.localizedDescription)"
                self.isRunning = false
            }
        }
    }

    // 停止 API 服务
    func stop() {
        guard let app = vApp else { return }
        status = "停止中..."
        Task {
            try? await app.asyncShutdown()
            self.serverTask?.cancel()
            self.vApp = nil
            self.isRunning = false
            self.status = "服务已停止"
        }
    }

    func openModelDirectory() {
        let path = modelPath.deletingLastPathComponent()
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path.path)
    }
}
