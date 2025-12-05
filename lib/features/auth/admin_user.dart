/// Admin User Model
/// Represents the currently authenticated admin user
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String username;
  final String companyId;
  final String? phoneNumber;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.companyId,
    this.phoneNumber,
  });

  /// Create AdminUser from Firestore data
  factory AdminUser.fromMap(Map<String, dynamic> data) {
    return AdminUser(
      id: data['admin_ID'] as String,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      companyId: data['company_ID'] as String? ?? '',
      phoneNumber: data['phone_number'] as String?,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'admin_ID': id,
      'name': name,
      'email': email,
      'username': username,
      'company_ID': companyId,
      'phone_number': phoneNumber,
    };
  }

  @override
  String toString() {
    return 'AdminUser(id: $id, name: $name, email: $email, company: $companyId)';
  }
}
