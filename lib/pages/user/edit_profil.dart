// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/utils/session_manager.dart';

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

  // MODIFIKASI UTAMA DI FUNGSI INI
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
        // Cek berdasarkan pesan sukses dari API, karena 'success' key tidak ada
        if (result['message'] == "Profil berhasil diperbarui" &&
            result['data'] != null) {
          // --- LOGIKA PENGGABUNGAN DATA DIMULAI DI SINI ---

          // 1. Ambil data user LENGKAP dari sesi lokal
          final User? oldUser = await _sessionManager.getUser();
          if (oldUser == null) throw Exception('Sesi pengguna tidak valid');

          // 2. Ambil data NAMA dan EMAIL BARU dari respons API
          final Map<String, dynamic> newData = result['data'];

          // 3. Buat objek User baru dengan MENGGABUNGKAN data lama dan baru
          final User mergedUser = User(
            id: oldUser.id,
            name: newData['name'] ?? oldUser.name, // Gunakan nama baru
            email: newData['email'] ?? oldUser.email, // Gunakan email baru
            profilePhotoPath: oldUser.profilePhotoPath, // Gunakan foto LAMA
            gender: oldUser.gender, // Gunakan gender LAMA
            training: oldUser.training, // Gunakan training LAMA
            batch: oldUser.batch, // Gunakan batch LAMA
            createdAt: oldUser.createdAt,
          );

          // 4. Simpan objek hasil gabungan yang sudah LENGKAP ke sesi
          await _sessionManager.saveUser(mergedUser);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Kembali & sinyalkan sukses
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
      appBar: AppBar(title: const Text('Edit Profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
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
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitForm,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.save),
              label: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Simpan Perubahan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
