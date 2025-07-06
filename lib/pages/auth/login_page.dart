import 'package:project3/common/theme.dart';
import 'package:project3/helper/database_helper.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/pages/admin/admin_dashboard__page.dart';
import 'package:project3/pages/auth/register_page.dart';
import 'package:project3/pages/user/user_dashboard_page.dart';
import 'package:project3/services/session_service.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    User? user = await DatabaseHelper().loginUser(_emailController.text, _passwordController.text);
    if (!mounted) return;

    setState(() => _isLoading = false);
    if (user != null) {
      await SessionService().saveSession(user.id);
      if (user.role == 'admin') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AdminDashboardPage()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => UserDashboardPage()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Gagal!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.fingerprint, size: 80, color: primaryColor),
                const SizedBox(height: 24),
                const Text("Selamat Datang Kembali", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                Text("Login untuk melanjutkan", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 48),
                TextField(controller: _emailController, decoration: customInputDecoration("Email", Icons.email_outlined), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                TextField(controller: _passwordController, decoration: customInputDecoration("Password", Icons.lock_outline), obscureText: true),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(onPressed: _login, style: primaryButtonStyle, child: const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Belum punya akun?", style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RegisterPage())),
                      child: const Text("Daftar di sini", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}