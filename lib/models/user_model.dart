// lib/models/user_model.dart

// Impor model lain yang dibutuhkan
import 'training_model.dart'; // Pastikan path ini benar
import 'batch_model.dart'; // Pastikan path ini benar

class User {
  final int id;
  final String name;
  final String email;
  final String? gender;
  final String? profilePhotoUrl;
  final String? createdAt;
  // [PERUBAHAN] Tambahkan properti untuk training dan batch
  final Datum? training;
  final BatchData? batch;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.gender,
    this.profilePhotoUrl,
    this.createdAt,
    // [PERUBAHAN] Tambahkan di constructor
    this.training,
    this.batch,
  });

  // [PERUBAHAN] Factory fromJson sekarang menangani objek training dan batch
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      // Sesuaikan key dengan JSON dari API
      gender: json['jenis_kelamin'],
      profilePhotoUrl:
          json['profile_photo_url'] ??
          json['profile_photo'], // Menangani kedua kemungkinan key
      createdAt: json['created_at'],
      // Cek jika data training/batch ada, lalu decode dari objek nested
      training: json['training'] != null
          ? Datum.fromJson(json['training'])
          : null,
      batch: json['batch'] != null ? BatchData.fromJson(json['batch']) : null,
    );
  }

  // [PERUBAHAN] Method toJson untuk menyimpan data ke SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'jenis_kelamin': gender,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt,
      // Ubah objek training/batch menjadi JSON jika tidak null
      'training': training?.toJson(),
      'batch': batch?.toJson(),
    };
  }
}
