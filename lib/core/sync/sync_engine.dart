import 'dart:async';

import 'package:injectable/injectable.dart';

import '../database/drift/app_database.dart';
import '../network/connectivity_monitor.dart';
import 'sync_status.dart';

/// Processes `sync_queue`: for each pending entity, encrypts the relevant
/// fields (via `core/security/encryption_engine`), pushes to Firestore,
/// then clears the pending flag (Section 6.1). Triggered on connectivity
/// change, app resume, and periodically.
///
/// Push/pull implementation is deferred until Firestore is configured
/// (`firebase_options.dart`) — this stub only exposes the status stream so
/// UI wiring (the three-state indicator) can be built against it now.
@lazySingleton
class SyncEngine {
  SyncEngine(this._database, this._connectivityMonitor);

  final AppDatabase _database;
  final ConnectivityMonitor _connectivityMonitor;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  StreamSubscription<bool>? _connectivitySubscription;

  Future<int> pendingCount() =>
      _database.select(_database.syncQueue).get().then((rows) => rows.length);

  void start() {
    _connectivitySubscription = _connectivityMonitor.onConnectivityChanged
        .listen((isOnline) {
          _statusController.add(
            isOnline ? SyncStatus.synced : SyncStatus.offlineWillSyncLater,
          );
          if (isOnline) {
            // TODO(sync): drain `sync_queue` — encrypt each pending row via
            // EncryptionEngine, push to Firestore, then clear `pendingSync`.
            // TODO(sync): pull-side merge using per-record `updatedAt`
            // last-write-wins, not per-collection (Section 6.1 point 3).
          }
        });
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _statusController.close();
  }
}
