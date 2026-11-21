import AVFoundation
import Foundation
import Observation
import Speech
import UIKit

/// 말을 글로 바꾸는 자리.
///
/// **오디오는 기기 밖으로 나가지 않는다.** `requiresOnDeviceRecognition`을 켜서 애플
/// 서버로 가는 길을 막는다. 이것은 제품 약속이고 CLAUDE.md 6장이 금지 항목으로 적어
/// 두었다. 켤 수 없는 기기에서는 받아쓰기를 아예 내주지 않는다 — 몰래 서버로 보내지
/// 않는다.
///
/// 멈추는 규칙(FEATURE-SPEC 2.3):
/// - **말이 1초 끊기면 누르지 않아도 그 자리에서 보낸다.** 글이 들어올 때마다 다시 센다.
/// - **듣기 시작하고 5초 동안 아무 말이 없으면 패널을 닫는다.**
@MainActor
@Observable
final class DictationController {
    /// 듣는 중인지. 패널이 이 값으로 뜨고 진다.
    private(set) var isListening = false
    /// 지금까지 받아쓴 글.
    private(set) var transcript = ""
    /// 거절·실패를 화면에 알릴 말.
    private(set) var errorMessage: String?

    /// 1초가 지나 스스로 끝났을 때. 받아쓴 글을 넘긴다.
    var onAutoSend: ((String) -> Void)?
    /// 5초 동안 아무 말이 없어 닫았을 때.
    var onSilentClose: (() -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko_KR"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silence: Task<Void, Never>?
    /// 앱이 앞에서 물러나는 것을 지켜보는 자리.
    private var resignObserver: (any NSObjectProtocol)?

    /// 이 기기에서 받아쓰기를 내줄 수 있는지.
    ///
    /// **못 하면 마이크를 그리지 않는다**(FEATURE-SPEC 2.3). 온디바이스 인식을 지원하지
    /// 않는 기기도 여기서 걸러진다.
    var isAvailable: Bool {
        guard let recognizer, recognizer.isAvailable else { return false }
        return recognizer.supportsOnDeviceRecognition
    }

    func start() async {
        guard !isListening, isAvailable else { return }
        errorMessage = nil
        transcript = ""

        guard await Self.authorize() else {
            errorMessage = "마이크와 받아쓰기를 허용해야 말로 적을 수 있어요."
            return
        }

        do {
            try beginSession()
        } catch {
            // 오디오 세션·엔진 실패는 감추지 않는다. 무엇이 안 되는지 알려야 한다.
            errorMessage = "마이크를 열지 못했어요."
            stop()
            return
        }

        isListening = true
        watchForeground()
        arm(heardSpeech: false)
    }

    /// **앱이 앞에서 물러나면 듣기를 멈춘다.**
    ///
    /// 화면을 나가는 것은 `onDisappear`가 잡지만 **앱이 뒤로 가는 것은 잡지 못한다** —
    /// 그대로 두면 사용자가 다른 앱에 가 있는 동안 마이크가 계속 열려 있다. 녹음을
    /// 저장하지 않더라도 켜 둔 채 잊은 마이크는 그 자체가 문제다. 받아쓴 글은 남고,
    /// 돌아와 마이크를 다시 누르면 이어서 적는다. Android도 같은 자리를 막아 두었다.
    private func watchForeground() {
        guard resignObserver == nil else { return }
        resignObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
    }

    /// 받아쓰기만 끈다. **화면을 나가지 않는다.**
    func stop() {
        silence?.cancel()
        silence = nil
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if let resignObserver {
            NotificationCenter.default.removeObserver(resignObserver)
            self.resignObserver = nil
        }
        isListening = false
    }

    // MARK: - 안쪽

    private func beginSession() throws {
        let audio = AVAudioSession.sharedInstance()
        try audio.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audio.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // 제품 약속. 끌 수 없다.
        request.requiresOnDeviceRecognition = true
        self.request = request

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        // **들어오는 소리가 없으면 여기서 멈춘다.** 입력이 없는 기기(시뮬레이터)나 다른
        // 앱이 마이크를 쥐고 있을 때 이 형식이 0채널 · 0Hz로 온다. 그대로 탭을 걸면
        // CoreAudio가 `abort()`로 **앱을 죽인다** — 던지는 오류가 아니라 잡을 수도
        // 없다. 미리 보고 "마이크를 열지 못했어요"로 받친다.
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw DictationError.noAudioInput
        }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        try engine.start()

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            let text = result?.bestTranscription.formattedString
            let failed = error != nil
            Task { @MainActor [weak self] in
                self?.heard(text, failed: failed)
            }
        }
    }

    private func heard(_ text: String?, failed: Bool) {
        guard isListening else { return }
        if failed, transcript.isEmpty {
            stop()
            onSilentClose?()
            return
        }
        guard let text, !text.isEmpty, text != transcript else { return }
        transcript = text
        // 글이 들어올 때마다 타이머를 처음부터 다시 센다.
        arm(heardSpeech: true)
    }

    /// 말이 끊긴 뒤를 센다. 들은 말이 있으면 보내고, 없으면 닫는다.
    private func arm(heardSpeech: Bool) {
        silence?.cancel()
        let wait = heardSpeech ? DictationTiming.send : DictationTiming.close
        silence = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled, let self, isListening else { return }
            let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            stop()
            if heardSpeech, !text.isEmpty {
                onAutoSend?(text)
            } else {
                onSilentClose?()
            }
        }
    }

    /// 허락을 묻는다.
    ///
    /// **`nonisolated`다.** `requestAuthorization`은 답을 아무 스레드에서나 돌려주는데,
    /// 이 자리가 `@MainActor`에 묶여 있으면 그 콜백이 메인이 아닌 곳에서 continuation을
    /// 깨우고 Swift 6의 격리 검사가 **앱을 그 자리에서 죽인다.** 허락을 처음 내주고
    /// 마이크를 누른 사람에게만 일어나 눈에 띄지 않았다. 여기서는 배우의 상태를
    /// 건드리지 않으므로 격리가 필요 없다.
    nonisolated private static func authorize() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }
}

/// 받아쓰기를 열지 못한 까닭.
enum DictationError: Error {
    /// 들어오는 소리가 없다. 입력이 없는 기기이거나 다른 앱이 마이크를 쥐고 있다.
    case noAudioInput
}

/// 멈추는 시각. Android와 같은 값이다.
enum DictationTiming {
    /// 말이 끊기고 이만큼 지나면 보낸다.
    static let send: Double = 1
    /// 시작하고 이만큼 아무 말이 없으면 닫는다.
    static let close: Double = 5
}
