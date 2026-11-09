# Guidelines: replace flutter_tts with native channel `medify/speech`

Reason: flutter_tts has no iOS SPM support. It is the only plugin keeping CocoaPods alive (remove-pods run). Owner rule: native channel when no SPM.

Scope: TTS only. Speech-to-text (voice capture) is a separate later slice; do not add it here.

## Allowed write paths

- `lib/core/voice/reminder_voice.dart` (rewrite to use channel)
- `lib/core/voice/native_speech_channel.dart` (new: thin Dart wrapper)
- `ios/Runner/AppDelegate.swift` (channel handler, AVSpeechSynthesizer)
- `ios/Runner/SpeechChannel.swift` (new, optional; keep handler small)
- `android/app/src/main/kotlin/**/MainActivity.kt` (channel handler, TextToSpeech)
- `test/core/voice/**` (new)

Do NOT touch: `pubspec.yaml`, `pubspec.lock` (another agent is editing them; flutter_tts removal from pubspec is a later step), `ios/Podfile*`, `ios/Pods/`, `ios/Flutter/*.xcconfig`, `ios/Runner.xcodeproj/**`, `ios/Runner.xcworkspace/**`, `lib/features/**`, `docs/**`. Do not commit.

## Channel contract

- Channel name: `medify/speech`
- Methods:
  - `speak` args `{ "text": String }` → returns null. Stops any current utterance first.
  - `stop` → returns null.
- Errors: `PlatformException` code `TTS_UNAVAILABLE` if the engine is missing. Dart side catches and no-ops (reminder still shows).
- Dart wrapper: `NativeSpeech` class, static `speak(String)` and `stop()`. Catch `MissingPluginException` and `PlatformException`; log, do not throw.

## Behaviour to preserve (from current reminder_voice.dart)

- Speak text `Medicine $name at $time.`
- Repeat every 8 s, max 3 utterances. Reuse existing timer logic exactly.
- Gate on `getIt<PreferencesService>().speakReminder` unchanged.
- Language: use device locale default, same as flutter_tts default.

## Steps

1. Read `lib/core/voice/reminder_voice.dart` and confirm its public API (`speakDose`, `stop`). Keep that API unchanged so callers do not change.
2. Create `native_speech_channel.dart` with the `NativeSpeech` wrapper.
3. Rewrite `reminder_voice.dart`: remove `import 'package:flutter_tts/flutter_tts.dart'`, replace `FlutterTts _tts` with `NativeSpeech`. Timer logic unchanged.
4. iOS: `AppDelegate.swift` uses the implicit engine (no `controller` variable). Register inside `didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge)`, after the existing `GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)` line. Messenger source: `engineBridge.pluginRegistry.registrar(forPlugin: "MedifySpeech")!.messenger()`. Create `FlutterMethodChannel(name: "medify/speech", binaryMessenger: messenger)`. Use `AVSpeechSynthesizer` + `AVSpeechUtterance(string:)`, `voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())`. `stop` calls `stopSpeaking(at: .immediate)`. Use `import AVFoundation`. No new pods, no frameworks beyond AVFoundation.
5. Android: in `MainActivity.kt`, create `TextToSpeech` in `onCreate`, register the same channel via `flutterEngine.dartExecutor.binaryMessenger` in `configureFlutterEngine`. `speak` → `tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, id)`. `stop` → `tts.stop()`. If `TextToSpeech` init status is not SUCCESS, return error `TTS_UNAVAILABLE` on speak.
6. Test: `test/core/voice/native_speech_channel_test.dart`. Use `TestDefaultBinaryMessengerBinding` to mock the `medify/speech` channel. Assert `speak` sends `{text: ...}`, `stop` sends stop, and a `PlatformException` is swallowed.

## Verification (stop on first failure)

- `dart format --set-exit-if-changed lib/core/voice test/core/voice`
- `flutter analyze lib/core/voice test/core/voice`
- `flutter test test/core/voice`
- `flutter build ios --no-codesign --debug` (expect it to still regenerate Pods because flutter_tts remains in pubspec; that is OK for this slice. Record result only.)
- `flutter build apk --debug` (must pass)
- `git status --short` must show changes only in the allowed paths plus pre-existing modified files.

## Stop and report if

- `MainActivity.kt` or `AppDelegate.swift` structure differs from what is described (e.g. already uses another plugin registration). Report the actual shape; do not guess.
- Any caller of `ReminderVoice` needs a signature change.
