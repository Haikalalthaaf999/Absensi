// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:project3/api/api_service.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/utils/session_manager.dart';


const Color primaryColor = Color(0xFF006769);
const Color fontColor = Colors.black87;
const Color accentColor = Color(0xFF046865);

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
    _liveTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
    _loadData();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _liveTime = DateFormat('hh:mm:ss a').format(DateTime.now());
      });
    }
  }

  Future<void> _loadData() async {
    // ... (Fungsi ini tidak perlu diubah) ...
    if (!mounted) return;
    if (_currentUser == null) {
      setState(() => _isLoading = true);
    }
    try {
      final token = await _sessionManager.getToken();
      _currentUser = await _sessionManager.getUser();
      if (token == null) {
        throw Exception("Sesi tidak valid, silakan login kembali.");
      }
      final results = await Future.wait([
        ApiService.getTodayAttendance(token),
        ApiService.getAbsenStats(token),
      ]);
      if (mounted) {
        final attendanceResult = results[0];
        if (attendanceResult['data'] != null) {
          _todayAttendance = Attendance.fromJson(attendanceResult['data']);
        } else {
          _todayAttendance = null;
        }
        final statsResult = results[1];
        if (statsResult['data'] != null &&
            statsResult['data'] is Map<String, dynamic>) {
          _absenStats = statsResult['data'];
        }
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(String? time24h) {
    if (time24h == null || time24h.isEmpty) {
      return '--:--';
    }
    try {
      final time = DateFormat('HH:mm').parse(time24h);
      return DateFormat('hh:mm a').format(time);
    } catch (e) {
      return '--:--';
    }
  }

  // --- WIDGET BUILD DIPERBARUI DENGAN STRUKTUR BARU ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/Background.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Konten
                SafeArea(
                  child: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _loadData,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildHeader(),
                              const SizedBox(height: 30),
                              _buildLiveAttendanceCard(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                        Divider(),
                        // -- BAGIAN BAWAH (BISA SCROLL) --
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Your Activity",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff046865),
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
                                    _buildCopyright(),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
          backgroundColor: Colors.white24,
          child: ClipOval(
            child: SizedBox(
              width: 52,
              height: 52,
              child: (_currentUser?.fullProfilePhotoUrl != null)
                  ? Image.network(
                      _currentUser!.fullProfilePhotoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white70,
                        );
                      },
                    )
                  : const Icon(Icons.person, size: 30, color: Colors.white70),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentUser?.name ?? "Nama Pengguna",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _currentUser?.email ?? "email@pengguna.com",
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

// card live attendance 
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
                fontFamily: 'DS-Digital',
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
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

  Widget _buildActivitySection() {
    if (_todayAttendance == null) {  
      return Card(
        color: Colors.black.withOpacity(0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const ListTile(
          leading: Icon(Icons.info_outline, color: Colors.white70),
          title: Text(
            "Belum Ada Aktivitas",
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "Silakan lakukan check-in",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (_todayAttendance!.status == 'izin') {
      return _buildActivityTile(
        icon: Icons.info_outline,
        title: "Izin",
        subtitle: _todayAttendance!.reason ?? 'Alasan tidak tersedia',
        time: '',
        status: "Izin Disetujui",
        color: Colors.orange.shade800,
      );
    }

    return Column(
      children: [
        _buildActivityTile(
          icon: Icons.fingerprint,
          title: "Check In",
          subtitle: DateFormat(
            'E, d MMM',
            'id_ID',
          ).format(DateTime.parse(_todayAttendance!.date)),
          time: _formatTime(_todayAttendance!.checkIn),
          status: "On Time",
          color: accentColor,
        ),
        const SizedBox(height: 10),
        _buildActivityTile(
          icon: Icons.logout,
          title: "Check Out",
          subtitle: DateFormat(
            'E, d MMM',
            'id_ID',
          ).format(DateTime.parse(_todayAttendance!.date)),
          time: _formatTime(_todayAttendance!.checkOut),
          status: _todayAttendance!.checkOut != null
              ? "Finished"
              : "Belum Check Out",
          color: _todayAttendance!.checkOut != null
              ? Colors.red
              : Colors.grey.shade700,
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
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(
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
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              if (status.isNotEmpty)
                Text(
                  status,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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
            color: Color(0xff046865),
          ),
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildStatGrid(),
      ],
    );
  }

  int _getStatAsInt(String key) {
    return num.tryParse(_absenStats[key]?.toString() ?? '0')?.toInt() ?? 0;
  }

  Widget _buildSummaryCard() {
    double percent = 0.0;
    final totalAbsen = _getStatAsInt('total_absen');
    final totalMasuk = _getStatAsInt('total_masuk');

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
                mainAxisAlignment: MainAxisAlignment.center,
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
      childAspectRatio: 1.8,
      children: [
        _buildStatGridItem(
          count: _getStatAsInt('total_masuk').toString(),
          label: "Present",
          color: Colors.green,
        ),
        _buildStatGridItem(
          count: _getStatAsInt('total_izin').toString(),
          label: "Absents/Izin",
          color: Colors.red,
        ),
        _buildStatGridItem(
          count: "0",
          label: "Early Leave",
          color: Colors.blue,
        ),
        _buildStatGridItem(count: "0", label: "Late", color: Colors.orange),
      ],
    );
  }

Widget _buildCopyright() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          '© ${DateTime.now().year} Sentinel. All Rights Reserved.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xff046865), 
          ),
        ),
      ),
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
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
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
