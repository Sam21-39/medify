import 'package:flutter/material.dart';

/// Global navigation service for handling navigation from background/notifications
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to a named route
  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and replace
  Future<dynamic>? navigateToAndReplace(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to a widget
  Future<dynamic>? navigateToWidget(Widget page) {
    return navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Pop navigation
  void goBack() {
    return navigatorKey.currentState?.pop();
  }

  /// Get current context
  BuildContext? get context => navigatorKey.currentContext;
}

