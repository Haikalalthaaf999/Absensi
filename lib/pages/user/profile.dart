// lib/screens/profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Sesuaikan path import dengan struktur proyek Anda
import 'package:project3/api/api_service.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/pages/auth/login_page.dart';
import 'package:project3/utils/session_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionManager _sessionManager = SessionManager();
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fungsi untuk memuat data profil lengkap dari API
  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _sessionManager.getToken();
      if (token == null) {
        _logout(); // Jika tidak ada token, langsung logout
        return;
      }

      // Panggil API untuk mendapatkan data profil terbaru dan terlengkap
      final result = await ApiService.getProfile(token);

      if (mounted) {
        if (result['data'] != null) {
          // Buat objek User dari data baru yang lebih lengkap
          final user = User.fromJson(result['data']);

          // Simpan kembali user yang sudah lengkap ke session
          await _sessionManager.saveUser(user);

          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
        } else {
          // Jika gagal, coba tampilkan data dari session lokal sebagai fallback
          final localUser = await _sessionManager.getUser();
          setState(() {
            _currentUser = localUser;
            _isLoading = false;
            _errorMessage = result['message'] ?? 'Gagal memuat data terbaru.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan jaringan: $e';
        });
      }
    }
  }

  Future<void> _logout() async {
    await _sessionManager.clearSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ), // Pastikan nama halaman login benar
        (route) => false,
      );
    }
  }

  Future<void> _changePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      // Format base64 yang umum diterima API
      final String base64Image =
          'data:image/${image.path.split('.').last};base64,${base64Encode(bytes)}';

      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        final token = await _sessionManager.getToken();
        if (token == null) return;

        final result = await ApiService.updateProfilePhoto(
          token: token,
          base64Photo: base64Image,
        );

        if (mounted && result['data'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
          );
          await _loadUserData(); // Muat ulang semua data agar foto baru muncul
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Gagal update foto.'),
              ),
            );
            setState(() => _isLoading = false);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Pengguna"),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _currentUser?.profilePhotoUrl != null
                              ? NetworkImage(_currentUser!.profilePhotoUrl!)
                              : null,
                          child: _currentUser?.profilePhotoUrl == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.photo_camera, size: 18),
                          label: const Text("Ubah Foto"),
                          onPressed: _changePhoto,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildProfileTile(
                          icon: Icons.person_outline,
                          title: "Nama Lengkap",
                          subtitle: _currentUser?.name,
                        ),
                        const Divider(height: 1),
                        _buildProfileTile(
                          icon: Icons.email_outlined,
                          title: "Email",
                          subtitle: _currentUser?.email,
                        ),
                        const Divider(height: 1),
                        _buildProfileTile(
                          icon: Icons.wc_outlined,
                          title: "Jenis Kelamin",
                          subtitle: _currentUser?.gender == 'L'
                              ? 'Laki-laki'
                              : _currentUser?.gender == 'P'
                              ? 'Perempuan'
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildProfileTile(
                          icon: Icons.school_outlined,
                          title: "Jurusan Training",
                          subtitle: _currentUser?.training?.title,
                        ),
                        const Divider(height: 1),
                        _buildProfileTile(
                          icon: Icons.tag_outlined,
                          title: "Batch",
                          subtitle: _currentUser?.batch?.batchKe,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget untuk membuat ListTile lebih rapi
  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle ?? "Tidak ada data",
        style: TextStyle(
          color: subtitle == null ? Colors.grey : null,
          fontStyle: subtitle == null ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}
