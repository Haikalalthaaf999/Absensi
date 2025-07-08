// lib/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String? gender;
  final String? profilePhotoUrl;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.gender,
    this.profilePhotoUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      gender: json['jenis_kelamin'],
      profilePhotoUrl: json['profile_photo_url'],
      createdAt: json['created_at'],
    );
  }
}