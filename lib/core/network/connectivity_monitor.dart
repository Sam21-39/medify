import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// Feeds `core/sync/`'s [SyncEngine] — the single source of truth for
/// "are we online" across the app.
abstract class ConnectivityMonitor {
  Stream<bool> get onConnectivityChanged;
  Future<bool> get isConnected;
}

@LazySingleton(as: ConnectivityMonitor)
class ConnectivityPlusMonitor implements ConnectivityMonitor {
  ConnectivityPlusMonitor() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
