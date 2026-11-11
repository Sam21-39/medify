import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/features/medicines/domain/voice/medicine_draft_parser.dart';
import 'package:medify/features/medicines/presentation/pages/voice_capture_page.dart';
import 'package:medify/l10n/app_localizations.dart';

const _method = MethodChannel('medify/stt');
const _events = EventChannel('medify/stt/events');

/// Records pops instead of routing, so the test can assert a draft was returned.
class _RecordingMessenger extends AppMessenger {
  final pops = <MedicineDraft?>[];

  @override
  void pop<T>([T? result]) => pops.add(result as MedicineDraft?);
}

void main() {
  late List<String> methods;
  late _RecordingMessenger messenger;
  MockStreamHandlerEventSink? sink;

  setUp(() {
    methods = [];
    sink = null;
    messenger = _RecordingMessenger();
    getIt.registerSingleton<AppMessenger>(messenger);

    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    binding.setMockMethodCallHandler(_method, (call) async {
      methods.add(call.method);
      return null;
    });
    binding.setMockStreamHandler(
      _events,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          sink = events;
        },
        onCancel: (arguments) {
          sink = null;
        },
      ),
    );
  });

  tearDown(() async {
    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    binding.setMockMethodCallHandler(_method, null);
    binding.setMockStreamHandler(_events, null);
    await getIt.reset();
  });

  Future<AppLocalizations> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VoiceCapturePage(),
      ),
    );
    await tester.pump();
    return AppLocalizations.of(tester.element(find.byType(VoiceCapturePage)))!;
  }

  /// Platform events are delivered on real async turns, outside fake time.
  Future<void> emit(WidgetTester tester, Map<String, Object?> event) async {
    sink!.success(event);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }

  Future<void> tapStop(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == l10n.voiceStop,
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'stop with no final cancels native and returns to idle after 3s',
    (tester) async {
      final l10n = await pumpPage(tester);
      expect(methods, contains('start'));

      await tapStop(tester, l10n);
      expect(methods, contains('stop'));
      expect(methods, isNot(contains('cancel')));

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(methods, contains('cancel'));
      expect(find.text(l10n.voiceTapToSpeak), findsOneWidget);
      expect(messenger.pops, isEmpty);
    },
  );

  testWidgets('a final arriving after the timeout does not pop', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);
    await tapStop(tester, l10n);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await emit(tester, {'type': 'final', 'text': 'aspirin 100 mg at 8am'});

    expect(messenger.pops, isEmpty);
  });

  testWidgets('a duplicate final pops only once', (tester) async {
    await pumpPage(tester);

    await emit(tester, {'type': 'final', 'text': 'aspirin 100 mg at 8am'});
    await emit(tester, {'type': 'final', 'text': 'aspirin 100 mg at 8am'});

    expect(messenger.pops, hasLength(1));
    expect(messenger.pops.single, isNotNull);
  });
}
