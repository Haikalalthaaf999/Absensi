// lib/pages/user/history_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/utils/session_manager.dart';

// --- Palet Warna Sesuai Desain ---
const Color appBarColor = Color(0xFF0D47A1); // Biru tua
const Color presentColor = Color(0xFF2E7D32); // Hijau
const Color absentColor = Color(0xFFD32F2F); // Merah
const Color lateColor = Colors.orange;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final SessionManager _sessionManager = SessionManager();  
  List<Attendance> _allHistory = [];
  List<Attendance> _filteredHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime.now();
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  String get _formattedMonth =>
      DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);

  // --- LOGIKA FILTER DIPERBAIKI TOTAL ---
  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _filteredHistory = _allHistory.where((item) {
        String status = item.status.toLowerCase();

        if (filter == 'All') return true;

        // Logika untuk filter 'Present'
        if (filter == 'Present') {
          return ['masuk', 'present', 'leave'].contains(status);
        }

        // Logika untuk filter 'Late In'
        if (filter == 'Late In') {
          return ['terlambat', 'late in'].contains(status);
        }

        // Logika untuk filter 'Absent'
        if (filter == 'Absent') {
          return ['absen', 'izin', 'sakit'].contains(status);
        }

        return false;
      }).toList();
    });
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = await _sessionManager.getToken();
      if (token == null) throw Exception("Token tidak valid");

      final startDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
      final endDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

      final result = await ApiService.getHistory(
        token,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        if (result['data'] != null && result['data'] is List) {
          _allHistory = (result['data'] as List)
              .map((item) => Attendance.fromJson(item))
              .toList();
        } else {
          _allHistory = [];
        }
        _applyFilter(_activeFilter);
      }
    } catch (e) {
      if (mounted) _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + increment,
        1,
      );
      _activeFilter = 'All';
    });
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7E9D7),
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text("Error: $_errorMessage"))
                : _buildGroupedHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => _changeMonth(-1),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: appBarColor),
              const SizedBox(width: 8),
              Text(
                _formattedMonth,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            "All",
            "Present",
            "Late In",
            "Absent",
          ].map((label) => _buildFilterChip(label)).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isActive = _activeFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (selected) {
          if (selected) _applyFilter(label);
        },
        selectedColor: Colors.blue.shade50,
        labelStyle: TextStyle(
          color: isActive ? appBarColor : Colors.black54,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isActive ? appBarColor : Colors.grey.shade300,
          ),
        ),
        elevation: isActive ? 1 : 0,
      ),
    );
  }

  Widget _buildGroupedHistoryList() {
    if (_filteredHistory.isEmpty) {
      return const Center(
        child: Text("Tidak ada data yang sesuai dengan filter."),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final attendanceItem = _filteredHistory[index];
        return _buildAttendanceDayCard(attendanceItem);
      },
    );
  }

  Widget _buildAttendanceDayCard(Attendance item) {
    final date = DateTime.parse(item.date);
    bool isAbsent = item.checkIn == null || item.checkIn!.isEmpty;

    String workingHours = '00h 00m';
    if (!isAbsent && item.checkOut != null) {
      try {
        final checkInTime = DateFormat('HH:mm').parse(item.checkIn!);
        final checkOutTime = DateFormat('HH:mm').parse(item.checkOut!);
        final duration = checkOutTime.isBefore(checkInTime)
            ? checkOutTime.add(const Duration(days: 1)).difference(checkInTime)
            : checkOutTime.difference(checkInTime);
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        workingHours =
            "${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m";
      } catch (e) {
        /* Biarkan default */
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 55,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.grey.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(date),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEE', 'id_ID').format(date),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isAbsent
                  ? Center(
                      child: Text(
                        item.reason ?? 'Tidak ada keterangan',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTimeDetail(Icons.login, item.checkIn, "Clock in"),
                        _buildTimeDetail(
                          Icons.logout,
                          item.checkOut,
                          "Clock out",
                        ),
                        _buildTimeDetail(
                          Icons.hourglass_empty_outlined,
                          workingHours,
                          "Working hrs",
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(item),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDetail(IconData icon, String? time, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: Colors.grey.shade500),
        const SizedBox(height: 6),
        Text(
          time ?? "--:--",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatusChip(Attendance item) {
    Color chipColor;
    String statusText;
    final status = item.status.toLowerCase();

    switch (status) {
      case 'masuk':
      case 'present':
      case 'leave':
        chipColor = presentColor;
        statusText = 'Present';
        break;
      case 'terlambat':
      case 'late in':
        chipColor = lateColor;
        statusText = 'Late In';
        break;
      default: // Termasuk 'izin', 'sakit', 'absen'
        chipColor = absentColor;
        statusText = 'Absent';
        break;
    }

    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          statusText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
