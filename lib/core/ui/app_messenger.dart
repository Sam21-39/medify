import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppMessenger {
  final scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  GoRouter? router;

  void show(String message, {bool error = false}) {
    final messenger = scaffoldKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFB91C1C) : null,
        ),
      );
  }

  void go(String location) => router?.go(location);

  Future<T?> push<T>(String location, {Object? extra}) {
    final router = this.router;
    if (router == null) return Future.value();
    return router.push<T>(location, extra: extra);
  }

  void pop<T>([T? result]) => router?.pop(result);
}
