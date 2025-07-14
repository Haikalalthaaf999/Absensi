// lib/screens/profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/pages/auth/login_page.dart';
import 'package:project3/pages/user/edit_profil.dart';
import 'package:project3/utils/session_manager.dart';

// Tema Warna
const Color profilePrimaryColor = Color(0xFF006769);
const Color profileAccentColor = Color(0xFF40A578);
const Color profileBackgroundColor = Color(0xFFF7E9D7);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// Tambahkan "with TickerProviderStateMixin" untuk animasi
class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final SessionManager _sessionManager = SessionManager();
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  // Controller untuk animasi
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- Fungsi Logika tidak berubah ---
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
          _animationController.forward(); // Mulai animasi setelah data dimuat
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
          _errorMessage = 'Gagal terhubung.';
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
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image == null || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await _sessionManager.getToken();
      if (token == null) return;
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final result = await ApiService.updateProfilePhoto(
        token: token,
        base64Photo: base64Image,
      );
      if (mounted && (result['success'] == true || result['data'] != null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: profileAccentColor,
          ),
        );
        await _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal update foto.')),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_currentUser == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser!),
      ),
    );
    if (result == true) {
      _loadUserData();
    }
  }

  // --- UI BUILDER DENGAN DESAIN KREASI BARU ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackgroundColor,
      appBar: AppBar(
        backgroundColor: profileBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: profilePrimaryColor,
              ),
              onPressed: _navigateToEditProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: profilePrimaryColor),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildAnimatedItem(0, _buildProfileHeader()),
                const SizedBox(height: 24),
                _buildAnimatedItem(1, _buildStatsRow()),
                const SizedBox(height: 24),
                _buildAnimatedItem(2, _buildInfoPanel()),
                const SizedBox(height: 24),
                _buildAnimatedItem(3, _buildLogoutButton()),
              ],
            ),
    );
  }

  // Widget untuk animasi fade-in
  Widget _buildAnimatedItem(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut),
            ),
          ),
      child: FadeTransition(opacity: _animationController, child: child),
    );
  }

  // --- WIDGET HELPER BARU KREASI SENDIRI ---

  Widget _buildProfileHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _changePhoto,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: profilePrimaryColor.withOpacity(0.2),
            child: CircleAvatar(
              radius: 37,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _currentUser?.fullProfilePhotoUrl != null
                  ? NetworkImage(_currentUser!.fullProfilePhotoUrl!)
                  : null,
              child: _currentUser?.fullProfilePhotoUrl == null
                  ? Icon(Icons.person, size: 40, color: Colors.grey.shade500)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${_currentUser?.name?.split(' ').first ?? ''}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "Selamat datang kembali!",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.tag,
            label: "Batch",
            value: _currentUser?.batch?.batchKe?.toString() ?? 'N/A',
            color: profileAccentColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.school_outlined,
            label: "Jurusan",
            value: _currentUser?.training?.title?.split(' ').first ?? 'N/A',
            color: profilePrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Detail Informasi",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.person_pin_outlined,
            "Nama Lengkap",
            _currentUser?.name,
          ),
          _buildInfoRow(
            Icons.alternate_email,
            "Alamat Email",
            _currentUser?.email,
          ),
          _buildInfoRow(
            Icons.people_alt_outlined,
            "Jenis Kelamin",
            _currentUser?.gender == 'L' ? 'Laki-laki' : 'Perempuan',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          Text(
            value ?? '-',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.logout_rounded),
      label: const Text("Log Out"),
      onPressed: _logout,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.shade200, width: 1.5),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}
 