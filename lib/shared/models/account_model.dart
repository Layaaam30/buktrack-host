/// Account Model
/// Represents a driver or conductor account
class Account {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String role; // 'driver' or 'conductor'
  final String availability; // 'available', 'on-duty', 'off-duty'
  final String? assignedBusId;
  final String? assignedBusNumber;
  final String? avatarUrl;
  final DateTime? lastLogin;
  final bool hasLoggedIn;

  Account({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.role,
    required this.availability,
    this.assignedBusId,
    this.assignedBusNumber,
    this.avatarUrl,
    this.lastLogin,
    this.hasLoggedIn = false,
  });

  // Get initials from name
  String get initials {
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // Get role display text
  String get roleText {
    return role == 'driver' ? 'Driver' : 'Conductor';
  }

  // Get availability display text
  String get availabilityText {
    switch (availability.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'on-duty':
        return 'On Duty';
      case 'off-duty':
        return 'Off Duty';
      default:
        return availability;
    }
  }

  // Check if account has assigned bus
  bool get hasAssignedBus => assignedBusId != null && assignedBusNumber != null;

  // Get last login text
  String get lastLoginText {
    if (!hasLoggedIn) return 'Never logged in';
    if (lastLogin == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(lastLogin!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Factory constructor for dummy data
  factory Account.dummy() {
    return Account(
      id: 'account_1',
      name: 'Joshua Periodico',
      username: 'joshua...',
      phone: '1234567890',
      role: 'conductor',
      availability: 'available',
      assignedBusId: 'bus_1',
      assignedBusNumber: 'QWE-321',
      hasLoggedIn: false,
    );
  }

  // Convert from JSON (for Firebase integration later)
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'conductor',
      availability: json['availability'] ?? 'available',
      assignedBusId: json['assignedBusId'],
      assignedBusNumber: json['assignedBusNumber'],
      avatarUrl: json['avatarUrl'],
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin'])
          : null,
      hasLoggedIn: json['hasLoggedIn'] ?? false,
    );
  }

  // Convert to JSON (for Firebase integration later)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'role': role,
      'availability': availability,
      'assignedBusId': assignedBusId,
      'assignedBusNumber': assignedBusNumber,
      'avatarUrl': avatarUrl,
      'lastLogin': lastLogin?.toIso8601String(),
      'hasLoggedIn': hasLoggedIn,
    };
  }
}
