// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:project3/pages/splash_page.dart';
import 'package:project3/pages/user/profile.dart'; // ⬅️ Tambahkan ini jika pakai pushNamed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); // Format tanggal lokal
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Absensi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple, fontFamily: 'Poppins'),
      home: const SplashScreen(),

      // ✅ Tambahkan semua named routes di sini
      routes: {
        '/user': (context) => const ProfileScreen(),
        // Tambahkan rute lain di sini jika diperlukan
      },
    );
  }
}
