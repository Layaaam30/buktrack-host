import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing companies (SuperAdmin only)
class CompanyManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new company
  Future<String> createCompany({
    required String companyName,
    required String email,
    required String contactNumber,
    required String address,
  }) async {
    try {
      // Check if company with same email already exists
      final existingCompany = await _firestore
          .collection('companies')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (existingCompany.docs.isNotEmpty) {
        throw 'A company with this email already exists';
      }

      // Create company document
      final companyRef = await _firestore.collection('companies').add({
        'company_name': companyName,
        'email': email.toLowerCase().trim(),
        'contact_number': contactNumber,
        'address': address,
        'registration_date': FieldValue.serverTimestamp(),
        'total_buses': 0,
      });

      return companyRef.id;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Get all companies
  Future<List<Map<String, dynamic>>> getAllCompanies() async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .orderBy('registration_date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw e.toString();
    }
  }

  /// Get company by ID
  Future<Map<String, dynamic>?> getCompanyById(String companyId) async {
    try {
      final doc = await _firestore.collection('companies').doc(companyId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Update company
  Future<void> updateCompany({
    required String companyId,
    required String companyName,
    required String email,
    required String contactNumber,
    required String address,
  }) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'company_name': companyName,
        'email': email.toLowerCase().trim(),
        'contact_number': contactNumber,
        'address': address,
      });
    } catch (e) {
      throw e.toString();
    }
  }

  /// Delete company (and optionally its admins)
  Future<void> deleteCompany(
    String companyId, {
    bool deleteAdmins = false,
  }) async {
    try {
      if (deleteAdmins) {
        // Delete all admins associated with this company
        final admins = await _firestore
            .collection('admins')
            .where('company_ID', isEqualTo: companyId)
            .get();

        final batch = _firestore.batch();
        for (final doc in admins.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Delete company
      await _firestore.collection('companies').doc(companyId).delete();
    } catch (e) {
      throw e.toString();
    }
  }

  /// Get company statistics
  Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    try {
      // Count admins
      final adminsSnapshot = await _firestore
          .collection('admins')
          .where('company_ID', isEqualTo: companyId)
          .get();

      // Count buses
      final busesSnapshot = await _firestore
          .collection('buses')
          .where('company_ID', isEqualTo: companyId)
          .get();

      // Count routes
      final routesSnapshot = await _firestore
          .collection('routes')
          .where('company_ID', isEqualTo: companyId)
          .get();

      // Count driver/conductors
      final staffSnapshot = await _firestore
          .collection('driver_conductors')
          .where('company_ID', isEqualTo: companyId)
          .get();

      return {
        'total_admins': adminsSnapshot.docs.length,
        'total_buses': busesSnapshot.docs.length,
        'total_routes': routesSnapshot.docs.length,
        'total_staff': staffSnapshot.docs.length,
      };
    } catch (e) {
      throw e.toString();
    }
  }
}
