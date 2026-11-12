import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppMessenger {
  final scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  GoRouter? router;

  void show(
    String message, {
    bool error = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = scaffoldKey.currentState;
    if (messenger == null) return;
    final hasAction = actionLabel != null && onAction != null;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFB91C1C) : null,
          duration: Duration(seconds: hasAction ? 5 : 4),
          action: hasAction
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
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
