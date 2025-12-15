import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'account_model.dart';

/// Account Firestore Service for Drivers and Conductors
/// Web-optimized with efficient queries and batch operations
class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Single collection for both drivers and conductors
  CollectionReference get _driverConductorsCollection {
    return _firestore.collection('driver_conductors');
  }

  /// Get all accounts (drivers and conductors) with real-time updates
  Stream<List<Account>> getAccountsStream(String companyId) {
    print('🔥 Starting real-time stream for accounts in company: $companyId');

    return _driverConductorsCollection
        .where('company_ID', isEqualTo: companyId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          final accounts = <Account>[];

          for (var doc in snapshot.docs) {
            try {
              final account = Account.fromFirestore(doc);
              accounts.add(account);
            } catch (e) {
              print('❌ Error parsing account ${doc.id}: $e');
            }
          }

          print('📊 Loaded ${accounts.length} accounts');
          return accounts;
        });
  }

  /// Get all accounts (one-time fetch)
  Future<List<Account>> getAccounts(String companyId) async {
    try {
      print('🔍 Fetching accounts for company: $companyId');

      final snapshot = await _driverConductorsCollection
          .where('company_ID', isEqualTo: companyId)
          .orderBy('created_at', descending: true)
          .get();

      final accounts = <Account>[];

      for (var doc in snapshot.docs) {
        try {
          final account = Account.fromFirestore(doc);
          accounts.add(account);
          print('✅ Loaded ${account.role}: ${account.name}');
        } catch (e) {
          print('❌ Error parsing account ${doc.id}: $e');
        }
      }

      print('📦 Total accounts loaded: ${accounts.length}');
      return accounts;
    } catch (e) {
      print('❌ Error fetching accounts: $e');
      throw Exception('Failed to fetch accounts: $e');
    }
  }

  /// Get single account by ID
  Future<Account?> getAccountById(String accountId, String role) async {
    try {
      print('🔍 Fetching account: $accountId ($role)');

      final doc = await _driverConductorsCollection.doc(accountId).get();

      if (!doc.exists) {
        print('❌ Account not found: $accountId');
        return null;
      }

      final account = Account.fromFirestore(doc);
      print('✅ Loaded account: ${account.name}');
      return account;
    } catch (e) {
      print('❌ Error fetching account: $e');
      throw Exception('Failed to fetch account: $e');
    }
  }

  /// Create a new account (driver or conductor)
  Future<String> createAccount(Account account, String plainPassword) async {
    try {
      print('➕ Creating ${account.role}: ${account.username}');

      // Check if username already exists
      final existingAccount = await _checkUsernameExists(account.username);
      if (existingAccount) {
        throw Exception('Username already exists');
      }

      // Hash password using bcrypt (Laravel compatible)
      final passwordHash = BCrypt.hashpw(plainPassword, BCrypt.gensalt());

      // Create account with hashed password
      final accountData = account
          .copyWith(
            passwordHash: passwordHash,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
          .toFirestore();

      // Add to collection
      final docRef = await _driverConductorsCollection.add(accountData);

      print('✅ Account created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating account: $e');
      throw Exception('Failed to create account: $e');
    }
  }

  /// Update an existing account
  Future<void> updateAccount(
    String accountId,
    String role,
    Account account,
  ) async {
    try {
      print('✏️ Updating account: $accountId');

      final accountData = account
          .copyWith(updatedAt: DateTime.now())
          .toFirestore();

      await _driverConductorsCollection.doc(accountId).update(accountData);

      print('✅ Account updated successfully');
    } catch (e) {
      print('❌ Error updating account: $e');
      throw Exception('Failed to update account: $e');
    }
  }

  /// Update specific fields of an account
  Future<void> updateAccountFields(
    String accountId,
    String role,
    Map<String, dynamic> fields,
  ) async {
    try {
      print('✏️ Updating account fields: $accountId');

      fields['updated_at'] = FieldValue.serverTimestamp();

      await _driverConductorsCollection.doc(accountId).update(fields);

      print('✅ Fields updated successfully');
    } catch (e) {
      print('❌ Error updating account fields: $e');
      throw Exception('Failed to update account fields: $e');
    }
  }

  /// Delete an account
  Future<void> deleteAccount(String accountId, String role) async {
    try {
      print('🗑️ Deleting account: $accountId');

      // ✅ VALIDATION: Check if account is in transit
      final accountDoc = await _driverConductorsCollection.doc(accountId).get();
      if (accountDoc.exists) {
        final data = accountDoc.data() as Map<String, dynamic>;
        final status = data['availability_status'] as String?;

        if (status == 'in_transit') {
          throw Exception(
            'Cannot delete account while driver/conductor is in transit. Please wait for trip to end.',
          );
        }
      }

      await _driverConductorsCollection.doc(accountId).delete();

      print('✅ Account deleted successfully');
    } catch (e) {
      print('❌ Error deleting account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Update account availability status
  Future<void> updateAvailabilityStatus(
    String accountId,
    String role,
    String status,
    String adminId,
  ) async {
    try {
      // ✅ VALIDATION: Check if account is assigned to a bus
      final accountDoc = await _driverConductorsCollection.doc(accountId).get();
      if (accountDoc.exists) {
        final data = accountDoc.data() as Map<String, dynamic>;
        final currentStatus = data['availability_status'] as String?;
        final assignedBusId = data['assigned_bus_ID'] as String?;

        // Block status change if assigned to a bus (standby or in_transit)
        // Only mobile app can change between standby <-> in_transit
        // Admin can only change status when NOT assigned to a bus
        if (assignedBusId != null && assignedBusId.isNotEmpty) {
          if (currentStatus == 'in_transit') {
            throw Exception('Cannot change status during active trip');
          } else if (currentStatus == 'standby') {
            throw Exception('Cannot change status while assigned to bus');
          }
        }
      }

      await _driverConductorsCollection.doc(accountId).update({
        'availability_status': status,
        'status_changed_by': adminId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Availability status updated to: $status');
    } catch (e) {
      print('❌ Error updating availability status: $e');
      // Re-throw the error as-is to preserve user-friendly messages
      rethrow;
    }
  }

  /// Set account leave dates
  Future<void> setLeave(
    String accountId,
    String role,
    DateTime startDate,
    DateTime endDate,
    String reason,
    String adminId,
  ) async {
    try {
      await _driverConductorsCollection.doc(accountId).update({
        'availability_status': 'on_leave',
        'leave_start_date': Timestamp.fromDate(startDate),
        'leave_end_date': Timestamp.fromDate(endDate),
        'leave_reason': reason,
        'status_changed_by': adminId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Leave set successfully');
    } catch (e) {
      throw Exception('Failed to set leave: $e');
    }
  }

  /// Clear account leave
  Future<void> clearLeave(String accountId, String role, String adminId) async {
    try {
      await _driverConductorsCollection.doc(accountId).update({
        'availability_status': 'available',
        'leave_start_date': null,
        'leave_end_date': null,
        'leave_reason': null,
        'status_changed_by': adminId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Leave cleared successfully');
    } catch (e) {
      throw Exception('Failed to clear leave: $e');
    }
  }

  /// Assign account to bus
  Future<void> assignToBus(
    String accountId,
    String role,
    String busId,
    String adminId,
  ) async {
    try {
      // ✅ VALIDATION: Check account status before assignment
      final accountDoc = await _driverConductorsCollection.doc(accountId).get();
      if (accountDoc.exists) {
        final data = accountDoc.data() as Map<String, dynamic>;
        final status = data['availability_status'] as String?;

        // Only allow assignment if status is "available"
        if (status != 'available') {
          if (status == 'in_transit') {
            throw Exception('Cannot assign bus during active trip');
          } else if (status == 'standby') {
            throw Exception(
              'Already assigned to a bus. Unassign first to change assignment',
            );
          } else if (status == 'on_leave') {
            throw Exception('Cannot assign bus while on leave');
          } else if (status == 'unavailable') {
            throw Exception('Cannot assign bus while unavailable');
          }
        }
      }

      await _driverConductorsCollection.doc(accountId).update({
        'assigned_bus_ID': busId,
        'assigned_by_admin': adminId,
        'assignment_date': FieldValue.serverTimestamp(),
        'availability_status': 'standby', // ✅ Set to standby when assigned
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Account assigned to bus: $busId');
    } catch (e) {
      print('❌ Error assigning to bus: $e');
      // Re-throw to preserve user-friendly messages
      rethrow;
    }
  }

  /// Unassign account from bus
  Future<void> unassignFromBus(
    String accountId,
    String role,
    String adminId,
  ) async {
    try {
      // ✅ VALIDATION: Check if account is in transit
      final accountDoc = await _driverConductorsCollection.doc(accountId).get();
      if (accountDoc.exists) {
        final data = accountDoc.data() as Map<String, dynamic>;
        final status = data['availability_status'] as String?;

        if (status == 'in_transit') {
          throw Exception(
            'Cannot unassign while driver/conductor is in transit. Please wait for trip to end.',
          );
        }
      }

      await _driverConductorsCollection.doc(accountId).update({
        'assigned_bus_ID': null,
        'current_route_ID': null,
        'unassigned_by_admin': adminId,
        'unassigned_at': FieldValue.serverTimestamp(),
        'availability_status': 'available',
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Account unassigned from bus');
    } catch (e) {
      print('❌ Error unassigning from bus: $e');
      throw Exception('Failed to unassign from bus: $e');
    }
  }

  /// Update password
  Future<void> updatePassword(
    String accountId,
    String role,
    String newPassword,
  ) async {
    try {
      final passwordHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      await _driverConductorsCollection.doc(accountId).update({
        'password_hash': passwordHash,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Password updated successfully');
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  /// Activate/deactivate account
  Future<void> setActiveStatus(
    String accountId,
    String role,
    bool isActive,
    String adminId,
  ) async {
    try {
      await _driverConductorsCollection.doc(accountId).update({
        'is_active': isActive,
        'status_changed_by': adminId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Active status updated to: $isActive');
    } catch (e) {
      throw Exception('Failed to update active status: $e');
    }
  }

  /// Get accounts by role
  Future<List<Account>> getAccountsByRole(String companyId, String role) async {
    try {
      final snapshot = await _driverConductorsCollection
          .where('company_ID', isEqualTo: companyId)
          .where('role', isEqualTo: role)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch accounts by role: $e');
    }
  }

  /// Get accounts by availability status
  Future<List<Account>> getAccountsByStatus(
    String companyId,
    String status,
  ) async {
    try {
      final snapshot = await _driverConductorsCollection
          .where('company_ID', isEqualTo: companyId)
          .where('availability_status', isEqualTo: status)
          .get();

      return snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch accounts by status: $e');
    }
  }

  /// Get available accounts (not assigned)
  Future<List<Account>> getAvailableAccounts(
    String companyId,
    String role,
  ) async {
    try {
      final snapshot = await _driverConductorsCollection
          .where('company_ID', isEqualTo: companyId)
          .where('role', isEqualTo: role)
          .where('availability_status', isEqualTo: 'available')
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Account.fromFirestore(doc))
          .where((account) => !account.isAssigned)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch available accounts: $e');
    }
  }

  /// Check if username exists
  Future<bool> _checkUsernameExists(String username) async {
    try {
      final query = await _driverConductorsCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get account statistics
  Future<Map<String, int>> getAccountStats(String companyId) async {
    try {
      final accounts = await getAccounts(companyId);

      return {
        'total': accounts.length,
        'drivers': accounts.where((a) => a.role == 'driver').length,
        'conductors': accounts.where((a) => a.role == 'conductor').length,
        'available': accounts
            .where((a) => a.availabilityStatus == 'available')
            .length,
        'in_transit': accounts
            .where((a) => a.availabilityStatus == 'in_transit')
            .length,
        'on_leave': accounts
            .where((a) => a.availabilityStatus == 'on_leave')
            .length,
        'assigned': accounts.where((a) => a.isAssigned).length,
        'active': accounts.where((a) => a.isActive).length,
      };
    } catch (e) {
      throw Exception('Failed to get account stats: $e');
    }
  }
}
