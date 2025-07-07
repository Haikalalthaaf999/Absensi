// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/utils/session_manager.dart';

// Definisikan warna tema agar mudah diubah
const Color primaryColor = Color(0xFF006769);
const Color presentColor = Color(0xFFE0F5E9);
const Color presentTextColor = Color(0xFF40A578);
const Color absentColor = Color(0xFFFDE1E1);
const Color absentTextColor = Color(0xFFD32F2F);
const Color leaveColor = Color(0xFFE1F5FE);
const Color leaveTextColor = Color(0xFF0277BD);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SessionManager _sessionManager = SessionManager();

  // State untuk data dan UI
  bool _isLoading = true;
  String? _token;
  List<Attendance> _historyList = [];
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    try {
      _token = await _sessionManager.getToken();
      if (_token == null) return;

      // Tentukan tanggal awal dan akhir dari bulan yang dipilih
      final firstDayOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
      );
      final lastDayOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      );

      final result = await ApiService.getHistory(
        _token!,
        startDate: DateFormat('yyyy-MM-dd').format(firstDayOfMonth),
        endDate: DateFormat('yyyy-MM-dd').format(lastDayOfMonth),
      );

      if (mounted && result['data'] != null) {
        final List<dynamic> historyData = result['data'];
        setState(() {
          _historyList = historyData
              .map((json) => Attendance.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat riwayat: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeMonth(int month) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + month,
      );
    });
    _loadHistoryData();
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '--:--';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '--:--';
    }
  }

  String _calculateWorkingHours(String? checkIn, String? checkOut) {
    if (checkIn == null || checkOut == null) return '00h 00m';
    try {
      final start = DateTime.parse(checkIn);
      final end = DateTime.parse(checkOut);
      final duration = end.difference(start);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
    } catch (e) {
      return '00h 00m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Absensi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          // Filter Chips (UI Only, logic can be added later)
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyList.isEmpty
                ? const Center(
                    child: Text('Tidak ada data absensi untuk bulan ini.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _historyList.length,
                    itemBuilder: (context, index) {
                      return _buildAttendanceItem(_historyList[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: primaryColor),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: primaryColor),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    // This is a UI placeholder.
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Chip(
              label: Text('Semua'),
              backgroundColor: primaryColor,
              labelStyle: TextStyle(color: Colors.white),
            ),
            SizedBox(width: 8),
            Chip(label: Text('Cuti')),
            SizedBox(width: 8),
            Chip(label: Text('Terlambat')),
            SizedBox(width: 8),
            Chip(label: Text('Absen')),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(Attendance attendance) {
    DateTime date = DateTime.parse(
      attendance.checkIn ?? DateTime.now().toIso8601String(),
    );

    Widget statusChip = _getStatusChip(attendance.status ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(date),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEE').format(date),
                    style: const TextStyle(color: Colors.grey),
                  ), // EEE for short day name
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimeColumn('Check In', _formatTime(attendance.checkIn)),
                  _buildTimeColumn(
                    'Check Out',
                    _formatTime(attendance.checkOut),
                  ),
                  _buildTimeColumn(
                    'Jam Kerja',
                    _calculateWorkingHours(
                      attendance.checkIn,
                      attendance.checkOut,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            statusChip,
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String title, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _getStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'masuk':
        bgColor = presentColor;
        textColor = presentTextColor;
        text = 'Hadir';
        break;
      case 'izin':
        bgColor = leaveColor;
        textColor = leaveTextColor;
        text = 'Izin';
        break;
      default:
        bgColor = absentColor;
        textColor = absentTextColor;
        text = 'Absen';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
