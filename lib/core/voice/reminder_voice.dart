import 'dart:async';

import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/core/voice/native_speech_channel.dart';

class ReminderVoice {
  Timer? _repeat;
  int _said = 0;

  Future<void> speakDose({required String name, required String time}) async {
    if (!getIt<PreferencesService>().speakReminder) return;
    await stop();
    _said = 0;
    await _say(name, time);
    _repeat = Timer.periodic(const Duration(seconds: 8), (_) {
      _say(name, time);
    });
  }

  Future<void> _say(String name, String time) async {
    if (_said >= 3) {
      await stop();
      return;
    }
    _said++;
    await NativeSpeech.speak('Medicine $name at $time.');
  }

  Future<void> stop() async {
    _repeat?.cancel();
    _repeat = null;
    await NativeSpeech.stop();
  }
}
