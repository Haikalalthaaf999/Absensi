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
    await Future.delayed(
      const Duration(seconds: 4),
    ); // Sedikit lebih lama untuk menikmati logo & animasi

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
    return Scaffold(
      backgroundColor: Color(0xffF7E9D7),
      body: Center(
        // Menggunakan Column untuk menyusun widget secara vertikal
        child: Column(
          mainAxisAlignment: MainAxisAlignment
              .center, // Pusatkan item di tengah secara vertikal
          children: [
            // 1. Widget untuk menampilkan logo Anda
            Image.asset(
              'assets/images/logoabsens.png', // Path ke file logo Anda
              width: 300, // Sesuaikan ukuran logo
              height: 300,
            ),
            // 2. Widget untuk animasi Lottie
            Lottie.asset(
              'assets/animations/loading3.json', // Path ke file animasi Anda
              width: 200,
              height: 200,
              fit: BoxFit.fill,
            ),
          ],
        ),
      ),
    );
  }
}
