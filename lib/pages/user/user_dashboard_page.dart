import 'dart:async';
import 'package:project3/common/theme.dart';
import 'package:project3/helper/database_helper.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/pages/auth/login_page.dart';
import 'package:project3/pages/user/history_page.dart';
import 'package:project3/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserDashboardPage extends StatefulWidget {
  @override
  _UserDashboardPageState createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  User? _currentUser;
  Attendance? _openAttendance;
  bool _isLoading = true;
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final userId = await SessionService().getUserId();
    if (userId != null) {
      _currentUser = await DatabaseHelper().getUserById(userId);
      _openAttendance = await DatabaseHelper().getOpenAttendance(userId);
    }
    setState(() => _isLoading = false);
  }

  void _handleClockAction() async {
    // TODO: Tambahkan validasi lokasi (geofencing) di sini
    if (_openAttendance == null) { // Clock In
      await DatabaseHelper().clockIn(_currentUser!.id, 'Lokasi Dummy');
    } else { // Clock Out
      await DatabaseHelper().clockOut(_openAttendance!.id, 'Lokasi Dummy');
    }
    _loadUserData();
  }

  void _logout() async {
    await SessionService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (c) => LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: textColor))],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildHeaderCard(),
                    const SizedBox(height: 24),
                    _buildActionCard(),
                    const Spacer(),
                    _buildHistoryButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Halo, Selamat Datang!", style: TextStyle(color: Colors.purple.shade800, fontSize: 16)),
            Text(_currentUser?.nama ?? "Pengguna", style: const TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _buildActionCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 10)]),
        child: Column(
          children: [
            Text(DateFormat.yMMMMEEEEd('id_ID').format(_currentTime), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 12),
            Text(DateFormat.Hms('id_ID').format(_currentTime), style: const TextStyle(color: textColor, fontSize: 42, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(_openAttendance != null ? Icons.logout : Icons.login, size: 28),
                label: Text(_openAttendance != null ? "CLOCK OUT" : "CLOCK IN", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: _handleClockAction,
                style: primaryButtonStyle.copyWith(padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 20))),
              ),
            ),
            const SizedBox(height: 8),
            Text(_openAttendance != null ? "Anda sudah masuk. Jangan lupa clock out!" : "Anda belum absen. Silakan clock in.", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );

  Widget _buildHistoryButton() => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.history),
          label: const Text("Lihat Riwayat Absensi"),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(userId: _currentUser!.id))),
          style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: const BorderSide(color: primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      );
}