import 'package:project3/helper/database_helper.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/pages/admin/admin_dashboard__page.dart';
import 'package:project3/pages/auth/login_page.dart';
import 'package:project3/pages/user/user_dashboard_page.dart';
import 'package:project3/services/session_service.dart';
import 'package:flutter/material.dart';
// 1. Import library Lottie
import 'package:lottie/lottie.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    // Logika navigasi Anda tidak perlu diubah, sudah benar.
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final userId = await SessionService().getUserId();
    if (userId == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
      return;
    }

    User? user = await DatabaseHelper().getUserById(userId);
    if (user != null) {
      if (user.role == 'admin') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AdminDashboardPage()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => UserDashboardPage()));
      }
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // 2. Ganti widget di sini dengan Lottie.asset
        child: Lottie.asset(
          'assets/animations/loading.json', // Path ke file animasi Anda
          width: 200,
          height: 200,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}