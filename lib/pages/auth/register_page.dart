// lib/pages/auth/register_page.dart

import 'package:flutter/material.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/pages/auth/login_page.dart';

import '../../models/batch_model.dart';
import '../../models/training_model.dart';
import '../../models/user_model.dart';
import '../../utils/session_manager.dart';

// Tema Warna Aplikasi
const Color primaryColor = Color(0xFF006769);
const Color accentColor = Color(0xFF40A578);

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
  bool _isPasswordHidden = true;

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final results = await Future.wait([
        ApiService.getTrainings(),
        ApiService.getBatches(),
      ]);

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

  void _register() async {
    FocusScope.of(context).unfocus();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil! Silakan login.'),
              backgroundColor: accentColor,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Registrasi gagal'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: $e'),
              backgroundColor: Colors.red,
            ),
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
      backgroundColor: Color(0xffF7E9D7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return 'Email tidak boleh kosong';
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v))
                          return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (v) {
                        if (v!.isEmpty) return 'Password tidak boleh kosong';
                        if (v.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildGenderDropdown(),
                    const SizedBox(height: 16),
                    _buildTrainingDropdown(),
                    const SizedBox(height: 16),
                    _buildBatchDropdown(),
                    const SizedBox(height: 32),
                    _buildRegisterButton(),
                    const SizedBox(height: 24),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER UNTUK DESAIN BARU ---

  Widget _buildHeader() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 200,
        width: double.infinity,
        color: primaryColor,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'Buat Akun Baru',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Lengkapi data diri Anda',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _isPasswordHidden : false,
      decoration: _buildInputDecoration(
        label: label,
        icon: icon,
        isPassword: isPassword,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      hint: const Text('Pilih Jenis Kelamin'),
      decoration: _buildInputDecoration(
        label: 'Jenis Kelamin',
        icon: Icons.wc_outlined,
      ),
      items: const [
        DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
        DropdownMenuItem(value: 'P', child: Text('Perempuan')),
      ],
      onChanged: (value) => setState(() => _selectedGender = value),
      validator: (value) => value == null ? 'Wajib dipilih' : null,
    );
  }

  Widget _buildTrainingDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTrainingId,
      hint: Text(_isDataLoading ? 'Memuat...' : 'Pilih Jurusan Training'),
      isExpanded: true,
      decoration: _buildInputDecoration(
        label: 'Jurusan Training',
        icon: Icons.school_outlined,
      ),
      items: _trainings.map((Datum training) {
        return DropdownMenuItem<String>(
          value: training.id.toString(),
          child: Text(training.title, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _isDataLoading
          ? null
          : (value) => setState(() => _selectedTrainingId = value),
      validator: (value) => value == null ? 'Wajib dipilih' : null,
    );
  }

  Widget _buildBatchDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBatchId,
      hint: Text(_isDataLoading ? 'Memuat...' : 'Pilih Batch'),
      isExpanded: true,
      decoration: _buildInputDecoration(
        label: 'Batch',
        icon: Icons.tag_outlined,
      ),
      items: _batches.map((BatchData batch) {
        return DropdownMenuItem<String>(
          value: batch.id.toString(),
          child: Text(
            batch.batchKe ?? 'Batch tidak bernama',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isDataLoading
          ? null
          : (value) => setState(() => _selectedBatchId = value),
      validator: (value) => value == null ? 'Wajib dipilih' : null,
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () =>
                  setState(() => _isPasswordHidden = !_isPasswordHidden),
            )
          : null,
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text('Daftar'),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Sudah punya akun?"),
        TextButton(
          onPressed: () =>
              Navigator.pop(context), // Kembali ke halaman sebelumnya (Login)
          child: const Text(
            'Masuk di sini',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// Custom Clipper untuk membuat bentuk gelombang (sama seperti di login)
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.2, size.height - 30.0);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(
      size.width - (size.width / 3.25),
      size.height - 65,
    );
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
