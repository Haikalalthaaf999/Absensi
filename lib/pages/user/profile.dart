// lib/screens/profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/pages/auth/login_page.dart';
import 'package:project3/pages/user/edit_profil.dart';

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

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _sessionManager.getToken();
      if (token == null) {
        _logout();
        return;
      }

      final result = await ApiService.getProfile(token);

      if (mounted) {
        if (result['data'] != null) {
          final user = User.fromJson(result['data']);
          await _sessionManager.saveUser(user);
          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
        } else {
          final localUser = await _sessionManager.getUser();
          setState(() {
            _currentUser = localUser;
            _isLoading = false;
            _errorMessage = result['message'] ?? 'Gagal memuat data.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final localUser = await _sessionManager.getUser();
        setState(() {
          _currentUser = localUser;
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
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _changePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final String base64Image = base64Encode(bytes);

      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        final token = await _sessionManager.getToken();
        if (token == null) return;

        final result = await ApiService.updateProfilePhoto(
          token: token,
          base64Photo: base64Image,
        );

        // Asumsi API foto juga mengembalikan data user yang lengkap
        if (mounted && result['data'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
          );
          // Muat ulang data untuk refresh foto
          await _loadUserData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal update foto.')),
          );
          setState(() => _isLoading = false);
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

  // BARU: Fungsi untuk navigasi ke halaman edit profil
  Future<void> _navigateToEditProfile() async {
    if (_currentUser == null) return;

    // Navigasi ke halaman edit dan tunggu hasilnya
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser!),
      ),
    );

    // Jika halaman edit mengembalikan 'true' (artinya sukses),
    // muat ulang data di halaman ini untuk menampilkan perubahan.
    if (result == true) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // MODIFIKASI: Tombol edit dipindah ke sini agar lebih rapi
        actions: [
          if (!_isLoading) // Hanya tampilkan jika tidak sedang loading
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit Profil',
              onPressed: _navigateToEditProfile, // Panggil fungsi navigasi
            ),
        ],
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
                        _buildProfilePhoto(_currentUser?.fullProfilePhotoUrl),
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
                              : 'Tidak ada data',
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
                  // HAPUS: Tombol edit yang lama sudah dipindahkan ke AppBar
                ],
              ),
            ),
    );
  }

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

  Widget _buildProfilePhoto(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.black12,
        child: Icon(Icons.person, size: 50, color: Colors.white),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.black12,
      backgroundImage: NetworkImage(photoUrl),
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('Gagal memuat NetworkImage: $photoUrl, Error: $exception');
      },
    );
  }
}
