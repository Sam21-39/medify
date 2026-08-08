import 'package:injectable/injectable.dart';

import '../security/secure_storage/secure_storage_service.dart';

/// Writes a denormalized dose/medicine snapshot the native widget reads —
/// the widget process never opens Drift directly (Section 12). Bridged via
/// a platform channel; the plugin/channel wiring itself is out of scope for
/// this pass (needs an iOS App Group + WidgetKit extension target and an
/// Android Glance widget, both native-project changes).
abstract class HomeWidgetService {
  Future<void> writeSnapshot(String jsonSnapshot);
}

@LazySingleton(as: HomeWidgetService)
class SecureStorageHomeWidgetService implements HomeWidgetService {
  SecureStorageHomeWidgetService(this._secureStorage);

  final SecureStorageService _secureStorage;

  @override
  Future<void> writeSnapshot(String jsonSnapshot) async {
    await _secureStorage.writeHomeWidgetSnapshot(jsonSnapshot);
    // TODO(home-widget): trigger native refresh via platform channel /
    // `home_widget` plugin once the iOS App Group + WidgetKit extension
    // target and Android Glance widget exist in the native projects.
  }
}
