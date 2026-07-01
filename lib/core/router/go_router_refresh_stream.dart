import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a Stream (e.g. a Cubit's state stream) into a [Listenable] so
/// GoRouter's `refreshListenable` re-evaluates `redirect` whenever the
/// stream emits - used to react live to auth/consent state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
