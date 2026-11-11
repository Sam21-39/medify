import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:medify/core/constants/app_sizes.dart';
import 'package:medify/core/design/adaptive.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/core/voice/native_stt_channel.dart';
import 'package:medify/core/widgets/custom_button.dart';
import 'package:medify/core/widgets/medify_icon.dart';
import 'package:medify/features/medicines/domain/voice/medicine_draft_parser.dart';
import 'package:medify/gen/assets.gen.dart';
import 'package:medify/l10n/app_localizations.dart';

enum _VoiceStatus { listening, idle, denied, unavailable }

/// Speaks a medicine, shows the live transcript, then pops with a [MedicineDraft].
/// Nothing is saved here: the add form shows the draft for review.
class VoiceCapturePage extends StatefulWidget {
  const VoiceCapturePage({super.key});

  @override
  State<VoiceCapturePage> createState() => _VoiceCapturePageState();
}

class _VoiceCapturePageState extends State<VoiceCapturePage> {
  StreamSubscription<SttEvent>? _subscription;
  Timer? _stopTimer;
  final _gate = SttSessionGate();
  _VoiceStatus _status = _VoiceStatus.idle;
  String _transcript = '';
  bool _heardNothing = false;

  @override
  void initState() {
    super.initState();
    _subscription = NativeSttChannel.events.listen(_onEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _subscription?.cancel();
    _gate.close();
    NativeSttChannel.cancelQuietly();
    super.dispose();
  }

  Future<void> _start() async {
    _stopTimer?.cancel();
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _status = _VoiceStatus.listening;
      _transcript = '';
      _heardNothing = false;
    });
    _gate.open();
    try {
      await NativeSttChannel.start();
      // Left the page while the permission prompt was up.
      if (!mounted) NativeSttChannel.cancelQuietly();
    } on PlatformException catch (e) {
      if (e.code == 'cancelled') {
        // Stopped before it began: back to idle, nothing to report.
        _gate.close();
        if (mounted) setState(() => _status = _VoiceStatus.idle);
        return;
      }
      _setFailed(
        e.code == 'permission_denied'
            ? _VoiceStatus.denied
            : _VoiceStatus.unavailable,
        e.code == 'permission_denied'
            ? l10n.voicePermissionDenied
            : l10n.voiceUnavailable,
      );
    } on MissingPluginException {
      _setFailed(_VoiceStatus.unavailable, l10n.voiceUnavailable);
    }
  }

  void _setFailed(_VoiceStatus status, String message) {
    _gate.close();
    if (!mounted) return;
    setState(() => _status = status);
    getIt<AppMessenger>().show(message, error: true);
  }

  Future<void> _toggle() async {
    if (_status == _VoiceStatus.listening) {
      await NativeSttChannel.stop();
      // No final or error after stop: stop waiting and return to idle.
      _stopTimer?.cancel();
      _stopTimer = Timer(const Duration(seconds: 3), () {
        _gate.close();
        NativeSttChannel.cancelQuietly();
        if (mounted) setState(() => _status = _VoiceStatus.idle);
      });
    } else {
      await _start();
    }
  }

  void _onEvent(SttEvent event) {
    if (!_gate.accepting || !mounted) return;
    _stopTimer?.cancel();
    // Terminal events end the session: a duplicate final is dropped.
    if (event.isFinal || event.errorCode != null) _gate.close();
    if (event.errorCode != null) {
      _setFailed(
        _VoiceStatus.unavailable,
        AppLocalizations.of(context)!.voiceUnavailable,
      );
      return;
    }
    if (!event.isFinal) {
      setState(() => _transcript = event.text);
      return;
    }
    if (event.text.trim().isEmpty) {
      setState(() {
        _status = _VoiceStatus.idle;
        _heardNothing = true;
      });
      return;
    }
    setState(() => _status = _VoiceStatus.idle);
    getIt<AppMessenger>().pop<MedicineDraft>(
      MedicineDraftParser.parse(event.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listening = _status == _VoiceStatus.listening;
    final failed =
        _status == _VoiceStatus.denied || _status == _VoiceStatus.unavailable;

    final String hint;
    if (listening) {
      hint = l10n.voiceListening;
    } else if (_heardNothing) {
      hint = l10n.voiceNoSpeech;
    } else if (failed) {
      hint = l10n.voiceEnterManually;
    } else {
      hint = l10n.voiceTapToSpeak;
    }

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: l10n.voiceInputTitle,
        useNativeToolbar: false,
      ),
      body: MedifyAdaptive.body(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            children: [
              const Spacer(),
              Semantics(
                button: true,
                label: listening ? l10n.voiceStop : l10n.voiceStartListening,
                child: Material(
                  color: listening
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggle,
                    child: SizedBox(
                      width: 128,
                      height: 128,
                      child: Center(
                        child: MedifyIcon(
                          Assets.icons.voiceNote,
                          size: 64,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              Text(
                hint,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingM),
              if (_transcript.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    child: Text(
                      _transcript,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (_status == _VoiceStatus.idle && !_heardNothing) ...[
                const SizedBox(height: AppSizes.paddingM),
                Text(
                  l10n.voiceExample,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (failed) ...[
                CustomButton(
                  text: l10n.voiceEnterManually,
                  icon: Icons.edit_note,
                  onPressed: () =>
                      getIt<AppMessenger>().pop(const MedicineDraft()),
                ),
                const SizedBox(height: AppSizes.paddingM),
              ],
              TextButton(
                onPressed: () {
                  _gate.close();
                  NativeSttChannel.cancelQuietly();
                  getIt<AppMessenger>().pop<MedicineDraft>();
                },
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
