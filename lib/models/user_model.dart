// lib/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String? profilePhotoUrl; // <-- 1. FIELD ADDED (nullable)

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoUrl, // <-- 2. ADDED TO CONSTRUCTOR
  });

  // Factory constructor updated to handle the new field
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePhotoUrl: json['profile_photo_url'], // <-- 3. ADDED FROM JSON
    );
  }
}
