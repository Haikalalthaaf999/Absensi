// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:project3/api/api_service.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/pages/user/checkin_page.dart';

import 'package:project3/utils/session_manager.dart';

const Color primaryColor = Color(0xFF006769);
const Color fontColor = Colors.black87;
const Color accentColor = Color(0xFF40A578);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SessionManager _sessionManager = SessionManager();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  User? _currentUser;
  Attendance? _todayAttendance;
  Map<String, dynamic> _absenStats = {};
  bool _isLoading = true;
  String? _errorMessage;

  late String _liveTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _liveTime = DateFormat('HH:mm').format(DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
    _loadData();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _liveTime = DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  // PERBAIKAN UTAMA: Logika baru untuk memuat data
  Future<void> _loadData() async {
    if (!mounted) return;
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final token = await _sessionManager.getToken();
      _currentUser = await _sessionManager.getUser();

      if (token == null) {
        throw Exception("Sesi tidak valid, silakan login kembali.");
      }

      // 1. Cek data lokal terlebih dahulu
      final localAttendance = await _sessionManager
          .getTodayAttendanceFromLocal();

      if (localAttendance != null) {
        if (mounted) {
          setState(() {
            _todayAttendance = localAttendance;
          });
        }
      } else {
        // 2. Jika tidak ada data lokal, baru panggil API
        final attendanceResult = await ApiService.getTodayAttendance(token);
        if (mounted && attendanceResult['data'] != null) {
          _todayAttendance = Attendance.fromJson(attendanceResult['data']);
        } else {
          _todayAttendance = null;
        }
      }

      // Selalu panggil statistik dari API untuk data terbaru
      final statsResult = await ApiService.getAbsenStats(token);
      if (mounted &&
          statsResult['data'] != null &&
          statsResult['data'] is Map<String, dynamic>) {
        _absenStats = statsResult['data'];
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // PERBAIKAN: Fungsi navigasi yang akan me-refresh setelah kembali
  void _navigateToMapScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
    // Panggil _loadData setelah kembali dari MapScreen untuk memastikan sinkronisasi
    _loadData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PERBAIKAN: Ganti FloatingActionButton untuk navigasi
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToMapScreen,
        backgroundColor: accentColor,
        child: const Icon(Icons.location_on, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ... (sisa UI Anda, termasuk BottomNavigationBar)
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/Background.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SafeArea(
                  child: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(),
                          const SizedBox(height: 30),
                          _buildLiveAttendanceCard(),
                          const SizedBox(height: 30),
                          const Text(
                            "Your Activity",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildActivitySection(),
                          const SizedBox(height: 24),
                          _buildStatisticsSection(),
                          if (_errorMessage != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0,
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 80), // Beri ruang untuk FAB
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 26,
            backgroundImage: _currentUser?.profilePhotoUrl != null
                ? NetworkImage(_currentUser!.profilePhotoUrl!)
                : null,
            child: _currentUser?.profilePhotoUrl == null
                ? const Icon(Icons.person, size: 30, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentUser?.name ?? "Nama Pengguna",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _currentUser?.email ?? "email@pengguna.com",
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveAttendanceCard() {
    return Card(
      color: Colors.black.withOpacity(0.25),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Live Attendance",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _liveTime,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: const TextStyle(color: Colors.white70),
            ),
            const Divider(height: 30, thickness: 1, color: Colors.white24),
            const Text(
              "Office Hours: 08:00 AM - 05:00 PM",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatApiTime(String? dateTimeString) {
    if (dateTimeString == null) return '--:--';
    try {
      return DateFormat(
        'HH:mm',
      ).format(DateTime.parse(dateTimeString).toLocal());
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildActivitySection() {
    final today = DateFormat('E, d MMM').format(DateTime.now());

    if (_todayAttendance == null) {
      return _buildActivityTile(
        icon: Icons.info_outline,
        title: "Belum Ada Aktivitas",
        subtitle: today,
        time: "",
        status: "Belum Absen",
      );
    }

    if (_todayAttendance!.status == 'izin') {
      return _buildActivityTile(
        icon: Icons.info_outline,
        title: "Izin",
        subtitle: _todayAttendance!.reason ?? 'Alasan tidak tersedia',
        time: _formatApiTime(_todayAttendance!.date.toIso8601String()),
        status: "Izin Disetujui",
      );
    }

    return Column(
      children: [
        _buildActivityTile(
          icon: Icons.fingerprint,
          title: "Check In",
          subtitle: today,
          time: _todayAttendance!.checkIn ?? '--:--',
          status: "On Time",
        ),
        const SizedBox(height: 10),
        _buildActivityTile(
          icon: Icons.logout,
          title: "Check Out",
          subtitle: today,
          time: _todayAttendance!.checkOut ?? '--:--',
          status: _todayAttendance!.checkOut != null
              ? "Finished"
              : "Belum Check Out",
        ),
      ],
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (status.isNotEmpty)
                Text(
                  status,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Statistics",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildStatGrid(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    double percent = 0.0;
    final totalAbsen = _absenStats['total_absen'] as int? ?? 0;
    final totalMasuk = _absenStats['total_masuk'] as int? ?? 0;

    if (totalAbsen > 0) {
      percent = totalMasuk / totalAbsen;
    }

    return Card(
      color: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: CircularPercentIndicator(
                radius: 45.0,
                lineWidth: 8.0,
                percent: percent,
                center: const Icon(
                  Icons.pie_chart,
                  color: Colors.white,
                  size: 35,
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Text(
                    "${(percent * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Attendance Rate",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatGridItem(
          count: (_absenStats['total_hadir']?.toString()) ?? '0',
          label: "Present",
          color: Colors.green,
        ),
        _buildStatGridItem(
          count: (_absenStats['total_izin']?.toString()) ?? '0',
          label: "Absents/Izin",
          color: Colors.red,
        ),
        _buildStatGridItem(
          count: "0",
          label: "Early Leave",
          color: Colors.blue,
        ),
        _buildStatGridItem(
          count: (_absenStats['total_terlambat']?.toString()) ?? '0',
          label: "Late",
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatGridItem({
    required String count,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border(top: BorderSide(color: color, width: 4)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
