// lib/models/user_model.dart

import 'training_model.dart';
import 'batch_model.dart';
import 'package:project3/api/api_service.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? gender;
  final String? profilePhotoPath; // UBAH NAMA: Menyimpan path mentah dari API
  final String? createdAt;
  final Datum? training;
  final BatchData? batch;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.gender,
    this.profilePhotoPath, // UBAH NAMA
    this.createdAt,
    this.training,
    this.batch,
  });

  // ✨ TAMBAHKAN GETTER INI UNTUK MEMBUAT URL LENGKAP
  String? get fullProfilePhotoUrl {
    // Jika path null atau kosong, kembalikan null
    if (profilePhotoPath == null || profilePhotoPath!.isEmpty) {
      return null;
    }
    // Jika path sudah merupakan URL lengkap, langsung gunakan
    if (profilePhotoPath!.startsWith('http')) {
      return profilePhotoPath;
    }
    // Jika path adalah relatif, gabungkan dengan baseUrl dan path ke storage
    // PERHATIKAN: Laravel sering menggunakan /storage/, bukan /public/. Coba ganti ini.
    return '${ApiService.baseUrl}/public/$profilePhotoPath';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Ambil path foto dari 'profile_photo_url' atau 'profile_photo'
    String? photoPathFromApi =
        json['profile_photo_url'] ?? json['profile_photo'];

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      gender: json['jenis_kelamin'],
      profilePhotoPath: photoPathFromApi, // Simpan path mentah
      createdAt: json['created_at'],
      training: json['training'] != null
          ? Datum.fromJson(json['training'])
          : null,
      batch: json['batch'] != null ? BatchData.fromJson(json['batch']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'jenis_kelamin': gender,
      // Saat mengirim balik ke JSON, kita bisa gunakan nama field yang sesuai
      'profile_photo_url': profilePhotoPath,
      'created_at': createdAt,
      'training': training?.toJson(),
      'batch': batch?.toJson(),
    };
  }
}
