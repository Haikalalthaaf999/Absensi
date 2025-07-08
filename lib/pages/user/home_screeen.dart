import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Ganti 'project3' dengan nama project Anda jika berbeda
import 'package:project3/api/api_service.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/models/user_model.dart';
import 'package:project3/utils/session_manager.dart';

// Definisikan warna tema
const Color primaryColor = Color(0xFF006769);
const Color fontColor = Colors.black87;
const Color accentColor = Color(0xFF40A578);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE MANAGEMENT & LOGIC ---
  final SessionManager _sessionManager = SessionManager();

  User? _currentUser;
  Attendance? _todayAttendance;
  Map<String, dynamic>? _absenStats;
  bool _isLoading = true;
  String? _token;

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
    _loadData(); // Memuat data dari API saat halaman dibuka
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _liveTime = DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _token = await _sessionManager.getToken();
      _currentUser = await _sessionManager.getUser();

      if (_token != null) {
        final results = await Future.wait([
          ApiService.getTodayAttendance(_token!),
          ApiService.getAbsenStats(
            _token!,
          ), // Pastikan method ini ada di ApiService
        ]);

        if (mounted) {
          final attendanceResult = results[0];
          final statsResult = results[1];

          _todayAttendance = attendanceResult['data'] != null
              ? Attendance.fromJson(attendanceResult['data'])
              : null;
          _absenStats = statsResult['data'];
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Halaman ini HANYA me-return kontennya, tanpa Scaffold.
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              Image.asset(
                'assets/images/Background.jpg', // Pastikan nama file dan path benar
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _loadData, // Fungsi untuk pull-to-refresh
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
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                const Text(
                                  "Your Activity",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: fontColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildActivitySection(),
                                const SizedBox(height: 24),
                                _buildStatisticsSection(),
                                const SizedBox(height: 24),
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
          );
  }

  // Widget Header dengan data dinamis
  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          // Ganti dengan URL foto profil jika ada di model User
          backgroundImage: NetworkImage(
            _currentUser?.profilePhotoUrl ??
                'https://i.pinimg.com/736x/a8/7f/7b/a87f7b3b752ce0e0ac4195753e4202c5.jpg',
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

  // Widget Kartu Live Attendance (Jam tetap live)
  Widget _buildLiveAttendanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Live Attendance",
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _liveTime,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 30, thickness: 1),
            const Text(
              "Office Hours",
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              "08:00 AM - 05:00 PM",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: fontColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk format waktu dari API
  String _formatApiTime(String? dateTimeString) {
    if (dateTimeString == null) return '--:--';
    try {
      return DateFormat(
        'HH:mm a',
      ).format(DateTime.parse(dateTimeString).toLocal());
    } catch (e) {
      return '--:--';
    }
  }

  // Widget Sesi Aktivitas dengan data dinamis
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
        subtitle: _todayAttendance!.alasanIzin ?? '',
        time: _formatApiTime(_todayAttendance!.checkIn),
        status: "Izin Disetujui",
      );
    }

    return Column(
      children: [
        _buildActivityTile(
          icon: Icons.fingerprint,
          title: "Check In",
          subtitle: today,
          time: _formatApiTime(_todayAttendance!.checkIn),
          status: "On Time",
        ),
        const SizedBox(height: 10),
        _buildActivityTile(
          icon: Icons.logout,
          title: "Check Out",
          subtitle: today,
          time: _formatApiTime(_todayAttendance!.checkOut),
          status: _todayAttendance!.checkOut != null
              ? "Finished"
              : "Belum Check Out",
        ),
      ],
    );
  }

  // Widget template untuk setiap item aktivitas (sedikit modifikasi)
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
        color: primaryColor,
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

  // Widget Statistik dengan data dinamis
  Widget _buildStatisticsSection() {
    return Column(
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildStatGrid(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    double percent = 0.0;
    if (_absenStats != null && (_absenStats!['total_absen'] ?? 0) > 0) {
      percent =
          (_absenStats!['total_masuk'] ?? 0) / _absenStats!['total_absen'];
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: CircularPercentIndicator(
                radius: 50.0,
                lineWidth: 10.0,
                percent: percent,
                center: const Icon(
                  Icons.pie_chart,
                  color: primaryColor,
                  size: 40,
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: primaryColor,
                backgroundColor: primaryColor.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${(percent * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: accentColor,
                      ),
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Days",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          _absenStats?['total_absen']?.toString() ?? '0',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Days worked",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          _absenStats?['total_masuk']?.toString() ?? '0',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Hours",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          "...",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatGridItem(
                count: _absenStats?['total_masuk']?.toString() ?? '0',
                label: "Present",
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatGridItem(
                count: "0",
                label: "Early Leave",
                color: Colors.blue,
              ),
            ), // Data dummy, bisa ditambah dari API jika ada
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatGridItem(
                count: "0",
                label: "Late",
                color: Colors.orange,
              ),
            ), // Data dummy, bisa ditambah dari API jika ada
            Expanded(
              child: _buildStatGridItem(
                count: _absenStats?['total_izin']?.toString() ?? '0',
                label: "Absents/Izin",
                color: Colors.red,
              ),
            ),
          ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

// Catatan: Pastikan model User Anda memiliki field `profilePhotoUrl`
// atau sesuaikan dengan nama field foto profil yang ada.
