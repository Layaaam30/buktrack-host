import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _userIdKey = 'current_user_id';
  static const String _userTypeKey = 'user_type';
  static const String _isAuthenticatedKey = 'is_authenticated';

  static const String _adminIdKey = 'current_admin_id';

  // superadmin credentials
  static const String _superAdminEmail = 'superadmin@buktrack.com';
  static const String _superAdminPassword = 'SuperAdmin@2024!';
  static const String _superAdminId = 'superadmin_001';
  static const String _superAdminName = 'Super Administrator';
  static const String _superAdminUsername = 'superadmin';

  Future<Map<String, dynamic>?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final trimmedEmail = email.toLowerCase().trim();

      if (trimmedEmail == _superAdminEmail) {
        return await _signInAsSuperAdmin(password);
      }

      return await _signInAsAdmin(trimmedEmail, password);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>?> _signInAsSuperAdmin(String password) async {
    if (password != _superAdminPassword) {
      throw 'Incorrect password';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, _superAdminId);
    await prefs.setString(_userTypeKey, 'superadmin');
    await prefs.setBool(_isAuthenticatedKey, true);

    await prefs.setString(_adminIdKey, _superAdminId);

    return {
      'superadmin_ID': _superAdminId,
      'name': _superAdminName,
      'email': _superAdminEmail,
      'username': _superAdminUsername,
      'user_type': 'superadmin',
      'created_at': DateTime.now(),
    };
  }

  Future<Map<String, dynamic>?> _signInAsAdmin(
    String email,
    String password,
  ) async {
    final adminQuery = await _firestore
        .collection('admins')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (adminQuery.docs.isEmpty) {
      throw 'No admin account found with this email';
    }

    final adminDoc = adminQuery.docs.first;
    final adminData = adminDoc.data();

    final passwordHash = adminData['password_hash'] as String?;

    if (passwordHash == null) {
      throw 'Password data not found';
    }

    final isPasswordValid = BCrypt.checkpw(password, passwordHash);

    if (!isPasswordValid) {
      throw 'Incorrect password';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, adminDoc.id);
    await prefs.setString(_userTypeKey, 'admin');
    await prefs.setBool(_isAuthenticatedKey, true);

    await prefs.setString(_adminIdKey, adminDoc.id);

    final result = Map<String, dynamic>.from(adminData);
    result['admin_ID'] = adminDoc.id;
    result['user_type'] = 'admin';

    result.remove('password');
    result.remove('password_hash');

    return result;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userTypeKey);
    await prefs.setBool(_isAuthenticatedKey, false);

    await prefs.remove(_adminIdKey);
  }

  Future<Map<String, dynamic>?> getUserData(
    String userId,
    String userType,
  ) async {
    try {
      if (userType == 'superadmin') {
        return {
          'superadmin_ID': _superAdminId,
          'name': _superAdminName,
          'email': _superAdminEmail,
          'username': _superAdminUsername,
          'user_type': 'superadmin',
          'created_at': DateTime.now(),
        };
      } else {
        final adminDoc = await _firestore
            .collection('admins')
            .doc(userId)
            .get();

        if (!adminDoc.exists) {
          return null;
        }

        final adminData = Map<String, dynamic>.from(adminDoc.data()!);
        adminData['admin_ID'] = adminDoc.id;
        adminData['user_type'] = 'admin';

        adminData.remove('password');
        adminData.remove('password_hash');

        return adminData;
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>?> getAdminData(String adminId) async {
    return await getUserData(adminId, 'admin');
  }

  Future<bool> isSignedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuth = prefs.getBool(_isAuthenticatedKey) ?? false;
      final userId = prefs.getString(_userIdKey);
      final userType = prefs.getString(_userTypeKey);

      return isAuth && userId != null && userType != null;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getCurrentUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userTypeKey);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getCurrentAdminId() async {
    return await getCurrentUserId();
  }

  Future<bool> verifySession() async {
    if (!await isSignedIn()) {
      return false;
    }

    final userId = await getCurrentUserId();
    final userType = await getCurrentUserType();

    if (userId == null || userType == null) {
      return false;
    }

    try {
      if (userType == 'superadmin') {
        return userId == _superAdminId;
      } else {
        final adminDoc = await _firestore
            .collection('admins')
            .doc(userId)
            .get();
        return adminDoc.exists;
      }
    } catch (e) {
      return false;
    }
  }

  String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  Future<void> resetPassword(String email) async {
    throw 'Password reset not yet implemented';
  }
}
