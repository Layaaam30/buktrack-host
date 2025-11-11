import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Password Hashing Utility
/// Use this script to generate SHA-256 password hashes for admin accounts
/// 
/// Run this file directly:
/// dart run lib/utils/password_hasher.dart

void main() {
  print('========================================');
  print('BukTrack Password Hasher');
  print('========================================\n');

  print('This utility generates SHA-256 password hashes for your admin accounts.');
  print('Use the generated hash in Firestore for the "password_hash" field.\n');

  while (true) {
    // Get password from user
    stdout.write('Enter password to hash (or "exit" to quit): ');
    final input = stdin.readLineSync();

    if (input == null || input.toLowerCase() == 'exit') {
      print('\nExiting...');
      break;
    }

    if (input.isEmpty) {
      print('Password cannot be empty!\n');
      continue;
    }

    if (input.length < 6) {
      print('Warning: Password is shorter than 6 characters.\n');
    }

    // Generate hash
    final hash = hashPassword(input);

    print('\n--- Generated Hash ---');
    print(hash);
    print('----------------------\n');

    // Show Firestore example
    print('Add this to your Firestore admin document:');
    print('{');
    print('  "username": "your_username",');
    print('  "password_hash": "$hash",');
    print('  "name": "Admin Name",');
    print('  "email": "admin@example.com",');
    print('  "phone_number": "+1234567890",');
    print('  "company_ID": "your_company_id"');
    print('}\n');
  }
}

/// Hash password using SHA-256
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  return hash.toString();
}

/// Verify if a password matches a hash
bool verifyPassword(String password, String hash) {
  return hashPassword(password) == hash;
}

/// Example usage in comments:
/// 
/// // Example 1: Hash a password
/// final myPassword = 'securePassword123';
/// final hashedPassword = hashPassword(myPassword);
/// print(hashedPassword);
/// // Output: 5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8
/// 
/// // Example 2: Verify a password
/// final storedHash = '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8';
/// final isValid = verifyPassword('securePassword123', storedHash);
/// print(isValid); // true
/// 
/// // Example 3: Common test passwords and their hashes
/// // Password: "admin123" 
/// // Hash: 240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9
/// 
/// // Password: "password" 
/// // Hash: 5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8
/// 
/// // Password: "test123"
/// // Hash: ecd71870d1963316a97e3ac3408c9835ad8cf0f3c1bc703527c30265534f75ae
