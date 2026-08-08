import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

/// Shared Dio client for any REST calls outside Firebase's own SDKs (e.g.
/// third-party interaction-data lookups in Phase 4). Firebase traffic goes
/// through the Firebase SDKs directly, not through this client.
@lazySingleton
class ApiClient {
  ApiClient()
    : dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  final Dio dio;
}
