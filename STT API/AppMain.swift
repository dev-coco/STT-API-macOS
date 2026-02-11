import SwiftUI

@main
struct TranscribeApp: App {
    @StateObject private var serverManager = ServerManager()

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {

                titleHeader
                
                Divider().opacity(0.1)
                
                VStack(spacing: 22) {
                    modelCard

                    serverSettingsCard
                    
                    controlButton
                }
                .padding(25)
            }
            .frame(width: 420, height: 420)
            .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
            .onAppear {
                serverManager.checkModelExists()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }

    // 顶部 UI 组件
    var titleHeader: some View {
        HStack {
            // 图标
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 24))
                // 根据运行状态切换颜色
                .foregroundColor(serverManager.isRunning ? .green : .blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("STT API")
                    .font(.system(size: 20, weight: .bold))
                Text(serverManager.status)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(serverManager.isRunning ? .green : .secondary)
            }
            Spacer()
            
            // 打开本地模型存放目录
            Button(action: serverManager.openModelDirectory) {
                Image(systemName: "folder")
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
    }

    // 模型管理
    var modelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("模型资源").font(.system(size: 16, weight: .semibold))
                Spacer()
                
                // 模型加载完成后，显示绿勾标记
                if serverManager.isModelReady {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                }
            }
            
            // 下载过程中显示进度条
            if serverManager.isDownloading {
                ProgressView(value: serverManager.downloadProgress, total: 1.0)
                    .progressViewStyle(.linear)
            }

            // 加载状态按钮
            Button(action: { Task { await serverManager.downloadModel() } }) {
                Text(serverManager.isModelReady ? "模型已就绪" : "加载模型")
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .disabled(serverManager.isModelReady || serverManager.isDownloading)
        }
        .padding()
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
    }

    // API 设置组件
    var serverSettingsCard: some View {
        HStack {
            Label("监听端口", systemImage: "network")
                .font(.system(size: 16, weight: .semibold))
            
            Spacer()
            
            // 绑定 serverManager 中的端口字符串，默认 1643 端口
            TextField("1643", text: $serverManager.port)
                .textFieldStyle(.plain)
                .font(.system(size: 16, design: .monospaced))
                .frame(width: 80)
                .padding(6)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(6)
                .multilineTextAlignment(.center)
                // 服务器运行时不允许修改端口
                .disabled(serverManager.isRunning)
        }
        .padding()
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
    }

    // 启动按钮
    var controlButton: some View {
        Button(action: {
            // 根据当前状态切换按钮
            serverManager.isRunning ? serverManager.stop() : serverManager.start()
        }) {
            HStack {
                Image(systemName: serverManager.isRunning ? "stop.fill" : "play.fill")
                Text(serverManager.isRunning ? "停止服务" : "启动 API 服务")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            // 运行状态为红色，停止状态为蓝色
            .background(serverManager.isRunning ? Color.red : Color.blue)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        // 只有在加载完模型完成后按钮才可以使用
        .disabled(!serverManager.isModelReady && !serverManager.isRunning)
    }
}

// 辅助组件
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
