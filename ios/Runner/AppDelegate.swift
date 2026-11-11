import AVFoundation
import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var speechChannel: FlutterMethodChannel?
  private var sttChannel: FlutterMethodChannel?
  private var sttEventChannel: FlutterEventChannel?
  private var speechToText: SpeechToText?
  private var pathsChannel: FlutterMethodChannel?
  private var prefsChannel: FlutterMethodChannel?
  private var timezoneChannel: FlutterMethodChannel?
  private let synthesizer = AVSpeechSynthesizer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "MedifySpeech")!.messenger()
    let channel = FlutterMethodChannel(name: "medify/speech", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "speak":
        guard let args = call.arguments as? [String: Any], let text = args["text"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: "text is required", details: nil))
          return
        }
        self.synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        self.synthesizer.speak(utterance)
        result(nil)
      case "stop":
        self.synthesizer.stopSpeaking(at: .immediate)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    speechChannel = channel

    let stt = SpeechToText()
    let sttMessenger = engineBridge.pluginRegistry.registrar(forPlugin: "MedifyStt")!.messenger()
    let sttMethods = FlutterMethodChannel(name: "medify/stt", binaryMessenger: sttMessenger)
    sttMethods.setMethodCallHandler { call, result in
      switch call.method {
      case "start":
        stt.start(result: result)
      case "stop":
        stt.stop()
        result(nil)
      case "cancel":
        stt.cancel()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    let sttEvents = FlutterEventChannel(name: "medify/stt/events", binaryMessenger: sttMessenger)
    sttEvents.setStreamHandler(stt)
    sttChannel = sttMethods
    sttEventChannel = sttEvents
    speechToText = stt

    let pathsMessenger = engineBridge.pluginRegistry.registrar(forPlugin: "MedifyPaths")!.messenger()
    let paths = FlutterMethodChannel(name: "medify/paths", binaryMessenger: pathsMessenger)
    paths.setMethodCallHandler { call, result in
      switch call.method {
      case "documentsDirectory", "legacyDocumentsDirectory":
        guard let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
          result(FlutterError(code: "NO_DIRECTORY", message: "documents directory unavailable", details: nil))
          return
        }
        result(dir)
      case "temporaryDirectory":
        var dir = NSTemporaryDirectory()
        if dir.hasSuffix("/") { dir.removeLast() }
        result(dir)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    pathsChannel = paths

    let prefsMessenger = engineBridge.pluginRegistry.registrar(forPlugin: "MedifyPrefs")!.messenger()
    let prefs = FlutterMethodChannel(name: "medify/prefs", binaryMessenger: prefsMessenger)
    prefs.setMethodCallHandler { call, result in
      switch call.method {
      case "clearLegacyPrefs":
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("flutter.") {
          defaults.removeObject(forKey: key)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    prefsChannel = prefs

    let tzMessenger = engineBridge.pluginRegistry.registrar(forPlugin: "MedifyTimezone")!.messenger()
    let tz = FlutterMethodChannel(name: "medify/timezone", binaryMessenger: tzMessenger)
    tz.setMethodCallHandler { call, result in
      switch call.method {
      case "getLocalTimezone":
        result(TimeZone.current.identifier)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    timezoneChannel = tz
  }
}

/// On-device speech recognition for voice medicine entry.
/// Emits {type: partial|final, text} on the medify/stt/events stream.
private final class SpeechToText: NSObject, FlutterStreamHandler {
  private struct Unavailable: Error {}

  private let recognizer = SFSpeechRecognizer(locale: Locale.current)
  private let audioEngine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var lastText = ""
  private var eventSink: FlutterEventSink?
  // Bumped by stop/cancel/start so a start still waiting on permissions is dropped.
  private var generation = 0

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func start(result: @escaping FlutterResult) {
    cancel()
    let session = generation
    let superseded = FlutterError(code: "cancelled", message: "start superseded", details: nil)
    SFSpeechRecognizer.requestAuthorization { status in
      guard status == .authorized else {
        DispatchQueue.main.async {
          guard session == self.generation else { result(superseded); return }
          result(FlutterError(code: "permission_denied", message: "speech recognition not authorized", details: nil))
        }
        return
      }
      self.requestMicrophone { granted in
        DispatchQueue.main.async {
          guard session == self.generation else { result(superseded); return }
          guard granted else {
            result(FlutterError(code: "permission_denied", message: "microphone not authorized", details: nil))
            return
          }
          do {
            try self.begin()
            result(nil)
          } catch {
            self.finish()
            result(FlutterError(code: "unavailable", message: "speech recognition unavailable", details: nil))
          }
        }
      }
    }
  }

  func stop() {
    guard request != nil else {
      // Stop before begin() finished: drop the pending start.
      generation += 1
      return
    }
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    // Recognizer delivers the final result after endAudio, handled in begin().
    request?.endAudio()
  }

  /// Ends the session now, without a final result, and drops any pending start.
  func cancel() {
    generation += 1
    lastText = ""
    finish()
  }

  private func requestMicrophone(_ completion: @escaping (Bool) -> Void) {
    if #available(iOS 17.0, *) {
      AVAudioApplication.requestRecordPermission(completionHandler: completion)
    } else {
      AVAudioSession.sharedInstance().requestRecordPermission(completion)
    }
  }

  private func begin() throws {
    // On-device only: audio never leaves the phone. No model means no voice entry.
    guard let recognizer = recognizer, recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
      throw Unavailable()
    }
    finish()

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
    try session.setActive(true, options: .notifyOthersOnDeactivation)

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.requiresOnDeviceRecognition = true
    self.request = request
    lastText = ""

    let input = audioEngine.inputNode
    input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
      request.append(buffer)
    }
    audioEngine.prepare()
    try audioEngine.start()

    task = recognizer.recognitionTask(with: request) { [weak self] result, _ in
      DispatchQueue.main.async {
        // Ignore callbacks from a session that was stopped, cancelled or replaced.
        guard let self = self, self.request === request else { return }
        if let result = result {
          self.lastText = result.bestTranscription.formattedString
          if !result.isFinal {
            self.eventSink?(["type": "partial", "text": self.lastText])
            return
          }
        }
        // Final result, or an error after the user stopped: deliver what we heard.
        self.eventSink?(["type": "final", "text": self.lastText])
        self.finish()
      }
    }
  }

  private func finish() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    request = nil
    task?.cancel()
    task = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
