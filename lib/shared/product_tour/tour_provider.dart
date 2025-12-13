import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TourProvider with ChangeNotifier {
  static const String _tourCompletedKey = 'product_tour_completed';
  static const String _adminTourCompletedKey = 'admin_tour_completed';
  static const String _superadminTourCompletedKey = 'superadmin_tour_completed';

  bool _isTourActive = false;
  bool _tourCompleted = false;
  int _currentStep = 0;
  bool _isInitialized = false;

  bool get isTourActive => _isTourActive;
  bool get tourCompleted => _tourCompleted;
  int get currentStep => _currentStep;
  bool get isInitialized => _isInitialized;

  TourProvider() {
    _loadTourStatus();
  }

  Future<void> _loadTourStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _tourCompleted = prefs.getBool(_tourCompletedKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tour status: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> shouldShowTour(bool isSuperAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isSuperAdmin
        ? _superadminTourCompletedKey
        : _adminTourCompletedKey;
    return !(prefs.getBool(key) ?? false);
  }

  void startTour() {
    _isTourActive = true;
    _currentStep = 0;
    notifyListeners();
  }

  void nextStep() {
    _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void skipTour(bool isSuperAdmin) {
    _completeTour(isSuperAdmin);
  }

  void completeTour(bool isSuperAdmin) {
    _completeTour(isSuperAdmin);
  }

  Future<void> _completeTour(bool isSuperAdmin) async {
    _isTourActive = false;
    _tourCompleted = true;
    _currentStep = 0;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tourCompletedKey, true);
      final key = isSuperAdmin
          ? _superadminTourCompletedKey
          : _adminTourCompletedKey;
      await prefs.setBool(key, true);
    } catch (e) {
      debugPrint('Error saving tour status: $e');
    }
  }

  Future<void> resetTour() async {
    _isTourActive = false;
    _tourCompleted = false;
    _currentStep = 0;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tourCompletedKey);
      await prefs.remove(_adminTourCompletedKey);
      await prefs.remove(_superadminTourCompletedKey);
    } catch (e) {
      debugPrint('Error resetting tour: $e');
    }
  }
}
