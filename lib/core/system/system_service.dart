import 'package:package_info_plus/package_info_plus.dart';

class SystemService {
  Future<String> getVersionCode() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String appVersion = packageInfo.version;
    return appVersion;
  }
}
