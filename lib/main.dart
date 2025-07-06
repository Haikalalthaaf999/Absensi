import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:project3/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi locale untuk format tanggal Indonesia
  await initializeDateFormatting('id_ID', null); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Absensi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Poppins', // Anda bisa menambahkan font custom
      ),
      home: SplashPage(),
    );
  }
}