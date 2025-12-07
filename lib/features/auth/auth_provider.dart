import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'admin_user.dart';
import 'superadmin_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _userData;
  AdminUser? _currentAdminUser;
  SuperAdminUser? _currentSuperAdminUser;
  String? _errorMessage;
  String? _userType;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get userData => _userData;
  AdminUser? get currentAdminUser => _currentAdminUser;
  SuperAdminUser? get currentSuperAdminUser => _currentSuperAdminUser;

  SuperAdminUser? get currentSuperAdmin => _currentSuperAdminUser;
  AdminUser? get currentAdmin => _currentAdminUser;

  String? get errorMessage => _errorMessage;
  String? get userType => _userType;

  String? get userName => _userData?['name'];
  String? get userEmail => _userData?['email'];

  String? get userId {
    if (_userType == 'superadmin') {
      return _userData?['superadmin_ID'] as String?;
    } else {
      return _userData?['admin_ID'] as String?;
    }
  }

  String? get companyId => _userData?['company_ID'];

  @Deprecated('Use userData instead')
  Map<String, dynamic>? get adminData => _userData;
  @Deprecated('Use currentAdminUser instead')
  AdminUser? get currentUser => _currentAdminUser;
  @Deprecated('Use userName instead')
  String? get adminName => _userData?['name'];
  @Deprecated('Use userEmail instead')
  String? get adminEmail => _userData?['email'];
  @Deprecated('Use userId instead')
  String? get adminId => _userData?['admin_ID'];

  bool get isSuperAdmin => _userType == 'superadmin';
  bool get isAdmin => _userType == 'admin';

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final isSignedIn = await _authService.isSignedIn();

      if (isSignedIn) {
        final userId = await _authService.getCurrentUserId();
        final userType = await _authService.getCurrentUserType();

        if (userId != null && userType != null) {
          _userData = await _authService.getUserData(userId, userType);

          if (_userData != null && _userData!.isNotEmpty) {
            _isAuthenticated = true;
            _userType = userType;

            if (userType == 'superadmin') {
              _currentSuperAdminUser = SuperAdminUser.fromMap(_userData!);
              _currentAdminUser = null;
            } else {
              _currentAdminUser = AdminUser.fromMap(_userData!);
              _currentSuperAdminUser = null;
            }
          } else {
            _isAuthenticated = false;
            _userData = null;
            _currentAdminUser = null;
            _currentSuperAdminUser = null;
            _userType = null;
          }
        } else {
          _isAuthenticated = false;
          _userData = null;
          _currentAdminUser = null;
          _currentSuperAdminUser = null;
          _userType = null;
        }
      } else {
        _isAuthenticated = false;
        _userData = null;
        _currentAdminUser = null;
        _currentSuperAdminUser = null;
        _userType = null;
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _isAuthenticated = false;
      _userData = null;
      _currentAdminUser = null;
      _currentSuperAdminUser = null;
      _userType = null;
      _errorMessage = 'Failed to initialize authentication';
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userData = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (_userData != null && _userData!.isNotEmpty) {
        _isAuthenticated = true;
        _userType = _userData!['user_type'];

        if (_userType == 'superadmin') {
          _currentSuperAdminUser = SuperAdminUser.fromMap(_userData!);
          _currentAdminUser = null;
        } else {
          _currentAdminUser = AdminUser.fromMap(_userData!);
          _currentSuperAdminUser = null;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to sign in';
        _isAuthenticated = false;
        _currentAdminUser = null;
        _currentSuperAdminUser = null;
        _userType = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      _userData = null;
      _currentAdminUser = null;
      _currentSuperAdminUser = null;
      _userType = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _isAuthenticated = false;
      _userData = null;
      _currentAdminUser = null;
      _currentSuperAdminUser = null;
      _userType = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    final userId = await _authService.getCurrentUserId();
    final userType = await _authService.getCurrentUserType();

    if (userId != null && userType != null) {
      try {
        _userData = await _authService.getUserData(userId, userType);
        if (_userData != null && _userData!.isNotEmpty) {
          _userType = userType;

          if (userType == 'superadmin') {
            _currentSuperAdminUser = SuperAdminUser.fromMap(_userData!);
            _currentAdminUser = null;
          } else {
            _currentAdminUser = AdminUser.fromMap(_userData!);
            _currentSuperAdminUser = null;
          }
        }
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Failed to refresh user data';
        notifyListeners();
      }
    }
  }

  Future<bool> verifySession() async {
    try {
      return await _authService.verifySession();
    } catch (e) {
      return false;
    }
  }
}
