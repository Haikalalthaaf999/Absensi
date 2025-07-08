// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/pages/user/main_screen.dart';
import 'package:project3/utils/session_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  List<dynamic> _trainings = [];
  List<dynamic> _batches = [];
  String? _selectedTrainingId;
  String? _selectedBatchId;
  String? _selectedGender; // State untuk jenis kelamin
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    // Panggil kedua API karena sekarang /batches sudah publik
    try {
      final responses = await Future.wait([
        ApiService.getTrainings(),
        ApiService.getBatches(),
      ]);
      if (mounted) {
        setState(() {
          _trainings = responses[0]['data'] ?? [];
          _batches = responses[1]['data'] ?? [];
          _isDataLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDataLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data pilihan: $e')),
        );
      }
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final result = await ApiService.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          jenisKelamin: _selectedGender!,
          trainingId: int.parse(_selectedTrainingId!),
          batchId: int.parse(_selectedBatchId!),
        );

        if (mounted && result['data'] != null) {
          final token = result['data']['token'];
          final user = User.fromJson(result['data']['user']);
          await SessionManager().saveSession(token, user);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Registrasi berhasil!')));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        } else {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Registrasi gagal')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Akun Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Menggunakan ListView agar bisa di-scroll
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              // --- Dropdown Jenis Kelamin ---
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: const Text('Pilih Jenis Kelamin'),
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) => value == null ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 16),
              if (_isDataLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                DropdownButtonFormField<String>(
                  value: _selectedTrainingId,
                  hint: const Text('Pilih Jurusan Training'),
                  items: _trainings
                      .map(
                        (t) => DropdownMenuItem<String>(
                          value: t['id'].toString(),
                          child: Text(t['title'] ?? 'Not Found'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedTrainingId = value),
                  validator: (value) => value == null ? 'Wajib dipilih' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBatchId,
                  hint: const Text('Pilih Batch'),
                  items: _batches
                      .map(
                        (b) => DropdownMenuItem<String>(
                          value: b['id'].toString(),
                          child: Text(b['name'] ?? 'Not Found'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedBatchId = value),
                  validator: (value) => value == null ? 'Wajib dipilih' : null,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
