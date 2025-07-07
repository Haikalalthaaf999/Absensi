// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:project3/pages/auth/login_page.dart';
import 'package:project3/pages/user/main_screen.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

// Ganti 'project3' dengan nama project Anda jika berbeda

import 'package:project3/utils/session_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    // Memberi jeda agar splash screen terlihat
    await Future.delayed(const Duration(seconds: 3));

    final token = await _sessionManager.getToken();

    if (mounted) {
      if (token != null) {
        // Jika token ada, langsung ke halaman utama
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Jika tidak ada token, ke halaman login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Center(
        // Anda bisa menaruh logo di sini
       child: Lottie.asset(
          'assets/animations/amongus.json', // Path ke file animasi Anda
          width: 200,
          height: 200,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
