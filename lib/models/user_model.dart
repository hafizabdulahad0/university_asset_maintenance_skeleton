// File: lib/models/user_model.dart
// Model class for user data
class User {
  String? id; // uuid
  String name;
  String email;
  String role;
  String createdAt;
  String updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt = '',
    this.updatedAt = '',
  });

  // Convert a User into a map for inserting into the database
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    return map;
  }

  // Create a User object from a map retrieved from the database
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String?,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      createdAt: (map['created_at'] ?? '') as String,
      updatedAt: (map['updated_at'] ?? '') as String,
    );
  }
}
