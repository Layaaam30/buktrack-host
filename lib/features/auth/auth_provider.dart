import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Authentication Provider
/// Manages authentication state across the app
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _adminData;
  String? _errorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get adminData => _adminData;
  String? get errorMessage => _errorMessage;
  String? get adminName => _adminData?['name'];
  String? get adminEmail => _adminData?['email'];
  String? get adminId => _adminData?['admin_ID'];
  String? get companyId => _adminData?['company_ID'];

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize authentication state silently in background
  Future<void> _initializeAuth() async {
    try {
      // Check if user is signed in
      final isSignedIn = await _authService.isSignedIn();

      if (isSignedIn) {
        // Get admin ID from storage
        final adminId = await _authService.getCurrentAdminId();

        if (adminId != null) {
          // Load admin data
          _adminData = await _authService.getAdminData(adminId);
          _isAuthenticated = _adminData != null;
        } else {
          _isAuthenticated = false;
          _adminData = null;
        }
      } else {
        _isAuthenticated = false;
        _adminData = null;
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _isAuthenticated = false;
      _adminData = null;
      _errorMessage = 'Failed to initialize authentication';
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _adminData = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (_adminData != null) {
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to sign in';
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      _adminData = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _isAuthenticated = false;
      _adminData = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh admin data
  Future<void> refreshAdminData() async {
    final adminId = await _authService.getCurrentAdminId();

    if (adminId != null) {
      try {
        _adminData = await _authService.getAdminData(adminId);
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Failed to refresh admin data';
        notifyListeners();
      }
    }
  }

  /// Verify session is still valid
  Future<bool> verifySession() async {
    try {
      return await _authService.verifySession();
    } catch (e) {
      return false;
    }
  }
}
