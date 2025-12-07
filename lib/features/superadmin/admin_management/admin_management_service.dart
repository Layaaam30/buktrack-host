import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class AdminManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createAdmin({
    required String name,
    required String email,
    required String username,
    required String password,
    required String companyId,
    String? phoneNumber,
  }) async {
    try {
      final existingEmail = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        throw 'An admin with this email already exists';
      }

      final existingUsername = await _firestore
          .collection('admins')
          .where('username', isEqualTo: username.toLowerCase().trim())
          .limit(1)
          .get();

      if (existingUsername.docs.isNotEmpty) {
        throw 'An admin with this username already exists';
      }

      final companyDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .get();

      if (!companyDoc.exists) {
        throw 'Company not found';
      }

      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      final adminRef = await _firestore.collection('admins').add({
        'name': name,
        'email': email.toLowerCase().trim(),
        'username': username.toLowerCase().trim(),
        'password_hash': passwordHash,
        'company_ID': companyId,
        'phone_number': phoneNumber,
      });

      return adminRef.id;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getAllAdmins({String? companyId}) async {
    try {
      Query query = _firestore.collection('admins');

      if (companyId != null) {
        query = query.where('company_ID', isEqualTo: companyId);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['admin_ID'] = doc.id;
        data.remove('password_hash');
        data.remove('password');
        return data;
      }).toList();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>?> getAdminById(String adminId) async {
    try {
      final doc = await _firestore.collection('admins').doc(adminId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['admin_ID'] = doc.id;
      data.remove('password_hash');
      data.remove('password');
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> updateAdmin({
    required String adminId,
    required String name,
    required String email,
    required String username,
    String? phoneNumber,
  }) async {
    try {
      final existingEmail = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty &&
          existingEmail.docs.first.id != adminId) {
        throw 'Another admin with this email already exists';
      }

      final existingUsername = await _firestore
          .collection('admins')
          .where('username', isEqualTo: username.toLowerCase().trim())
          .limit(1)
          .get();

      if (existingUsername.docs.isNotEmpty &&
          existingUsername.docs.first.id != adminId) {
        throw 'Another admin with this username already exists';
      }

      await _firestore.collection('admins').doc(adminId).update({
        'name': name,
        'email': email.toLowerCase().trim(),
        'username': username.toLowerCase().trim(),
        'phone_number': phoneNumber,
      });
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> resetAdminPassword({
    required String adminId,
    required String newPassword,
  }) async {
    try {
      final passwordHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      await _firestore.collection('admins').doc(adminId).update({
        'password_hash': passwordHash,
      });
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> deleteAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).delete();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<int> getAdminCountForCompany(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .where('company_ID', isEqualTo: companyId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> transferAdminToCompany({
    required String adminId,
    required String newCompanyId,
  }) async {
    try {
      final companyDoc = await _firestore
          .collection('companies')
          .doc(newCompanyId)
          .get();

      if (!companyDoc.exists) {
        throw 'Company not found';
      }

      await _firestore.collection('admins').doc(adminId).update({
        'company_ID': newCompanyId,
      });
    } catch (e) {
      throw e.toString();
    }
  }
}
