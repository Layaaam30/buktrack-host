import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';

/// Authentication Service with Laravel-compatible bcrypt verification
/// This is Laravel's standard password hashing method
/// Optimized for lowest network latency
class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _adminIdKey = 'current_admin_id';
  static const String _isAuthenticatedKey = 'is_authenticated';

  /// Sign in with email and password
  /// Returns admin data if successful, null otherwise
  /// Optimized for lowest network latency with indexed query
  Future<Map<String, dynamic>?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Query Firestore for admin with matching email
      // Using indexed field for faster query performance
      final adminQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        throw 'No admin account found with this email';
      }

      final adminDoc = adminQuery.docs.first;
      final adminData = adminDoc.data();

      // Get bcrypt hash from Firestore (Laravel's 'password_hash' field)
      final passwordHash = adminData['password_hash'] as String?;

      if (passwordHash == null) {
        throw 'Password data not found';
      }

      // Verify password using bcrypt (locally, no network call)
      // This is compatible with Laravel's Hash::check()
      final isPasswordValid = BCrypt.checkpw(password, passwordHash);

      if (!isPasswordValid) {
        throw 'Incorrect password';
      }

      // Store admin ID in shared preferences for persistent session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_adminIdKey, adminDoc.id);
      await prefs.setBool(_isAuthenticatedKey, true);

      // Return admin data with ID
      final result = Map<String, dynamic>.from(adminData);
      result['admin_ID'] = adminDoc.id;

      // Remove sensitive data before returning
      result.remove('password');
      result.remove('password_hash');

      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminIdKey);
    await prefs.setBool(_isAuthenticatedKey, false);
  }

  /// Get admin data by admin ID
  Future<Map<String, dynamic>?> getAdminData(String adminId) async {
    try {
      final adminDoc = await _firestore.collection('admins').doc(adminId).get();

      if (!adminDoc.exists) {
        return null;
      }

      final adminData = Map<String, dynamic>.from(adminDoc.data()!);
      adminData['admin_ID'] = adminDoc.id;

      // Remove sensitive data
      adminData.remove('password');
      adminData.remove('password_hash');

      return adminData;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Check if user is signed in
  Future<bool> isSignedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuth = prefs.getBool(_isAuthenticatedKey) ?? false;
      final adminId = prefs.getString(_adminIdKey);

      return isAuth && adminId != null && adminId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get current admin ID from storage
  Future<String?> getCurrentAdminId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_adminIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Verify current session is still valid
  Future<bool> verifySession() async {
    if (!await isSignedIn()) {
      return false;
    }

    final adminId = await getCurrentAdminId();
    if (adminId == null) {
      return false;
    }

    try {
      final adminDoc = await _firestore.collection('admins').doc(adminId).get();
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Hash password for storage (when creating new admin)
  /// Compatible with Laravel's Hash::make()
  String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// Reset password (placeholder - implement based on your requirements)
  Future<void> resetPassword(String email) async {
    // TODO: Implement password reset logic
    // This could involve:
    // 1. Sending email with reset link
    // 2. Generating temporary password
    // 3. Updating password hash in Firestore
    throw 'Password reset not yet implemented';
  }
}
