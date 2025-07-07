// lib/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String? createdAt; // Bisa null jika tidak selalu ada

  User({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  // Factory constructor untuk membuat User dari JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      createdAt: json['created_at'],
    );
  }
}
