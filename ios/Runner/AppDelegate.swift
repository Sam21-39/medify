import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var speechChannel: FlutterMethodChannel?
  private var pathsChannel: FlutterMethodChannel?
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

    let pathsMessenger = engineBridge.pluginRegistry.registrar(forPlugin: "MedifyPaths")!.messenger()
    let paths = FlutterMethodChannel(name: "medify/paths", binaryMessenger: pathsMessenger)
    paths.setMethodCallHandler { call, result in
      switch call.method {
      case "documentsDirectory":
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
  }
}
