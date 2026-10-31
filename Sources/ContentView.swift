import SwiftUI
import Speech
import AVFoundation

@MainActor
final class VoiceModel: ObservableObject {
    @Published var lines: [ChatLine] = [.init(role: "model", content: "Chào bạn! Mình là Bách AI. Hãy nhập Gemini API key trong Cài đặt.")]
    @Published var input = ""
    @Published var apiKey = KeyStore.load()
    @Published var busy = false
    @Published var listening = false
    @Published var errorText: String?
    private let synthesizer = AVSpeechSynthesizer()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func saveKey() { KeyStore.save(apiKey) }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "vi-VN")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    func send() async {
        let message = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !busy else { return }
        guard !apiKey.isEmpty else { errorText = "Hãy nhập Gemini API key trước."; return }
        input = ""
        lines.append(.init(role: "user", content: message))
        busy = true
        defer { busy = false }
        do {
            let answer = try await GeminiService.reply(key: apiKey, history: lines)
            lines.append(.init(role: "model", content: answer))
            speak(answer)
        } catch { errorText = error.localizedDescription }
    }

    func toggleListening() async {
        if listening { stopListening(); return }
        let status = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard status == .authorized else { errorText = "Cần cấp quyền Nhận dạng giọng nói."; return }
        let micAllowed = await AVAudioApplication.requestRecordPermission()
        guard micAllowed else { errorText = "Cần cấp quyền Micro."; return }
        guard recognizer?.isAvailable == true else { errorText = "Nhận dạng tiếng Việt chưa khả dụng."; return }
        do {
            task?.cancel()
            task = nil
            request = SFSpeechAudioBufferRecognitionRequest()
            guard let request else { return }
            request.shouldReportPartialResults = true
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            let node = audioEngine.inputNode
            node.removeTap(onBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: node.outputFormat(forBus: 0)) { buffer, _ in
                request.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()
            listening = true
            task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let result { self?.input = result.bestTranscription.formattedString }
                    if error != nil { self?.stopListening() }
                }
            }
        } catch {
            stopListening()
            errorText = error.localizedDescription
        }
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        listening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

struct ContentView: View {
    @StateObject private var vm = VoiceModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(vm.lines) { line in
                                HStack {
                                    if line.role == "user" { Spacer(minLength: 30) }
                                    Text(line.content)
                                        .padding(12)
                                        .background(line.role == "user" ? Color.blue.opacity(0.2) : Color.gray.opacity(0.13))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    if line.role != "user" { Spacer(minLength: 30) }
                                }.id(line.id)
                            }
                        }.padding()
                    }
                    .onChange(of: vm.lines.count) { _, _ in
                        if let id = vm.lines.last?.id {
                            withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                        }
                    }
                }
                if vm.busy { ProgressView("Bách AI đang trả lời...") }
                HStack {
                    Button { Task { await vm.toggleListening() } } label: {
                        Image(systemName: vm.listening ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 35))
                    }
                    .accessibilityLabel(vm.listening ? "Dừng nghe" : "Bắt đầu nghe")
                    TextField("Nhắn hoặc nói tiếng Việt...", text: $vm.input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    Button { Task { await vm.send() } } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 30))
                    }
                    .disabled(vm.busy || vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Bách AI")
            .toolbar { Button("Cài đặt") { showSettings = true } }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    Form {
                        SecureField("Gemini API key", text: $vm.apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Lưu khóa trên iPhone") {
                            vm.saveKey()
                            showSettings = false
                        }
                        Text("API key lưu trong Keychain. Không chia sẻ lên GitHub.")
                            .font(.footnote)
                    }
                    .navigationTitle("Gemini")
                    .toolbar { Button("Đóng") { showSettings = false } }
                }
            }
            .alert("Bách AI", isPresented: Binding(
                get: { vm.errorText != nil },
                set: { if !$0 { vm.errorText = nil } }
            )) {
                Button("OK") { vm.errorText = nil }
            } message: {
                Text(vm.errorText ?? "")
            }
        }
    }
}
