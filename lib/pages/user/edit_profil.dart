// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/utils/session_manager.dart';

// Menggunakan tema warna dari halaman profil
const Color profilePrimaryColor = Color(0xFF006769);
const Color profileBackgroundColor = Color(0xFFF7E9D7);

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final SessionManager _sessionManager = SessionManager();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _sessionManager.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final updatedData = {
        'name': _nameController.text,
        'email': _emailController.text,
      };

      final result = await ApiService.updateProfile(
        token: token,
        data: updatedData,
      );

      if (mounted) {
        if (result['message'] == "Profil berhasil diperbarui" &&
            result['data'] != null) {
          // Logika penggabungan data sudah baik, kita pertahankan
          final User? oldUser = await _sessionManager.getUser();
          if (oldUser == null) throw Exception('Sesi pengguna tidak valid');

          final Map<String, dynamic> newData = result['data'];
          final User mergedUser = User(
            id: oldUser.id,
            name: newData['name'] ?? oldUser.name,
            email: newData['email'] ?? oldUser.email,
            profilePhotoPath: oldUser.profilePhotoPath,
            gender: oldUser.gender,
            training: oldUser.training,
            batch: oldUser.batch,
            createdAt: oldUser.createdAt,
          );

          await _sessionManager.saveUser(mergedUser);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception(result['message'] ?? 'Gagal memperbarui profil');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: profilePrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: profileBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: profilePrimaryColor,
        ), // Warna ikon back
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // Header dengan foto dan nama
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: widget.user.fullProfilePhotoUrl != null
                      ? NetworkImage(widget.user.fullProfilePhotoUrl!)
                      : null,
                  child: widget.user.fullProfilePhotoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.user.name ?? 'Nama Pengguna',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Input Nama
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration(
                label: 'Nama Lengkap',
                icon: Icons.person_outline,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Input Email
            TextFormField(
              controller: _emailController,
              decoration: _buildInputDecoration(
                label: 'Email',
                icon: Icons.email_outlined,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                  return 'Masukkan format email yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),

            // Tombol Simpan
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: profilePrimaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Menyimpan...'),
                      ],
                    )
                  : const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk styling input field agar konsisten
  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: profilePrimaryColor.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: profilePrimaryColor, width: 2),
      ),
    );
  }
}
