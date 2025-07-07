// lib/utils/session_manager.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // Import model User

class SessionManager {
  // Method untuk menyimpan sesi (token dan data user)
  Future<void> saveSession(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    // Simpan data user juga agar mudah diakses
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
  }

  // Method untuk mengambil token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Method untuk mengambil data user yang tersimpan
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Periksa jika ada token. Jika tidak, berarti tidak ada sesi.
    if (token == null) {
      return null;
    }

    return User(
      id: prefs.getInt('user_id') ?? 0,
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
    );
  }

  // Method untuk menghapus sesi (logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }
}
