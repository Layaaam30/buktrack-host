import 'package:flutter/material.dart';

/// Navigation Provider for SPA-style routing
/// Manages the current screen without using Flutter's Navigator
class NavigationProvider extends ChangeNotifier {
  String _currentRoute = '/dashboard';

  String get currentRoute => _currentRoute;

  /// Navigate to a new route without animations
  void navigateTo(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      notifyListeners();
    }
  }

  /// Check if a route is currently active
  bool isActive(String route) {
    return _currentRoute == route;
  }
}
