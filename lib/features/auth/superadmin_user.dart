class SuperAdminUser {
  final String id;
  final String name;
  final String email;
  final String username;
  final String? phoneNumber;
  final DateTime createdAt;

  SuperAdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.phoneNumber,
    required this.createdAt,
  });

  factory SuperAdminUser.fromMap(Map<String, dynamic> data) {
    return SuperAdminUser(
      id: data['superadmin_ID'] as String,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      phoneNumber: data['phone_number'] as String?,
      createdAt: (data['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'superadmin_ID': id,
      'name': name,
      'email': email,
      'username': username,
      'phone_number': phoneNumber,
      'created_at': createdAt,
    };
  }

  @override
  String toString() {
    return 'SuperAdminUser(id: $id, name: $name, email: $email)';
  }
}
