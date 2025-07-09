// lib/screens/main_screen.dart

import 'package:flutter/material.dart';

// Ganti 'project3' dengan nama project Anda jika berbeda
import 'package:project3/custom/bottom.dart';
import 'package:project3/pages/user/checkin_page.dart';
import 'package:project3/pages/user/history_page.dart';
import 'package:project3/pages/user/home_screeen.dart';
import 'package:project3/pages/user/profile.dart';



// Definisikan warna tema
const Color primaryColor = Color(0xFF006769);
const Color accentColor = Color(0xFF40A578);
const Color backgroundColor = Color(0xFFF7E9D7);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Daftar halaman ("kamar-kamar") yang akan ditampilkan
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MapScreen(),
    HistoryPage(),
    ProfileScreen(),
  ];

  // Fungsi untuk mengubah halaman saat navigasi ditekan
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // MainScreen memiliki Scaffold sebagai "rumah"
    return Scaffold(
      // Body akan menampilkan halaman sesuai index
      body: _widgetOptions.elementAt(_selectedIndex),

      // Di sinilah letak BottomNavigationBar
      bottomNavigationBar: CurvedNavigationBar(
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.map_outlined, size: 30, color: Colors.white),
          Icon(Icons.history, size: 30, color: Colors.white),
          Icon(Icons.person_outline, size: 30, color: Colors.white),
        ],
        index: _selectedIndex,
        color: primaryColor,
        buttonBackgroundColor: accentColor,
        backgroundColor: backgroundColor, // Warna di belakang bar
        height: 60.0,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Widget sementara untuk halaman lain yang belum dibuat
class PlaceholderWidget extends StatelessWidget {
  final Color color;
  final String title;
  const PlaceholderWidget({
    super.key,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: color.withOpacity(0.2),
        child: Center(child: Text(title, style: const TextStyle(fontSize: 24))),
      ),
    );
  }
}
