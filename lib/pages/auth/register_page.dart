// lib/pages/auth/register_page.dart

import 'package:flutter/material.dart';

// Sesuaikan path ini dengan struktur proyek Anda
import 'package:project3/api/api_service.dart';
import 'package:project3/pages/auth/login_page.dart';
import '../../models/batch_model.dart';
import '../../models/training_model.dart';
import '../../models/user_model.dart';
import '../../utils/session_manager.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- State untuk Dropdown (sudah menggunakan model) ---
  List<Datum> _trainings = [];
  List<BatchData> _batches = [];
  String? _selectedTrainingId;
  String? _selectedBatchId;
  String? _selectedGender;
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  // Fungsi untuk memuat data dari API menggunakan model
  Future<void> _loadDropdownData() async {
    try {
      final trainingFuture = ApiService.getTrainings();
      final batchFuture = ApiService.getBatches();

      final results = await Future.wait([trainingFuture, batchFuture]);

      final trainingResponse = results[0] as ListJurusan;
      final batchResponse = results[1] as BatchResponse;

      if (mounted) {
        setState(() {
          _trainings = trainingResponse.data;
          _batches = batchResponse.data ?? [];
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

  // Fungsi untuk mengirim data registrasi
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
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Registrasi gagal')),
            );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan saat registrasi: $e')),
          );
        }
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
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),

              // Dropdown Jenis Kelamin
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: const Text('Pilih Jenis Kelamin'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) => value == null ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 16),

              // Tampilkan loading atau dropdown
              if (_isDataLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Dropdown Jurusan/Training
                DropdownButtonFormField<String>(
                  value: _selectedTrainingId,
                  hint: const Text('Pilih Jurusan Training'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _trainings.map((Datum training) {
                    return DropdownMenuItem<String>(
                      value: training.id.toString(),
                      child: Text(training.title),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedTrainingId = value),
                  validator: (value) => value == null ? 'Wajib dipilih' : null,
                ),
                const SizedBox(height: 16),

                // Dropdown Batch
                DropdownButtonFormField<String>(
                  value: _selectedBatchId,
                  hint: const Text('Pilih Batch'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _batches.map((BatchData batch) {
                    return DropdownMenuItem<String>(
                      value: batch.id.toString(),
                      child: Text(batch.batchKe ?? 'Batch tidak bernama'),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedBatchId = value),
                  validator: (value) => value == null ? 'Wajib dipilih' : null,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Daftar', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
