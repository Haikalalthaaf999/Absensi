// lib/pages/user/history_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/utils/session_manager.dart';

// Definisikan warna tema agar mudah diubah
const Color primaryColor = Color(0xFF006769);
const Color accentColor = Color(0xFF40A578);

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

  String get _formattedMonth {
    return DateFormat('MMMM yyyy').format(_selectedMonth);
  }

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      if (filter == 'All') {
        _filteredHistory = _allHistory;
      } else {
        if (filter == 'Absent') {
          _filteredHistory = _allHistory
              .where(
                (item) =>
                    item.status.toLowerCase() == 'izin' ||
                    item.status.toLowerCase() == 'sakit',
              )
              .toList();
        } else {
          _filteredHistory = _allHistory
              .where(
                (item) => item.status.toLowerCase() == filter.toLowerCase(),
              )
              .toList();
        }
      }
    });
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
          final List<dynamic> data = result['data'];
          setState(() {
            _allHistory = data
                .map((item) => Attendance.fromJson(item))
                .toList();
            _applyFilter(_activeFilter);
            _isLoading = false;
          });
        } else {
          setState(() {
            _allHistory = [];
            _filteredHistory = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _allHistory = [];
          _filteredHistory = [];
        });
      }
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + increment,
        _selectedMonth.day,
      );
      _activeFilter = 'All';
    });
    _loadHistory();
  }

  // BARU: Fungsi untuk menangani penghapusan data absensi
  Future<void> _deleteAttendanceItem(int id) async {
    final token = await _sessionManager.getToken();
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sesi tidak valid.")));
      return;
    }

    try {
      final result = await ApiService.deleteAttendance(token: token, id: id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Data berhasil dihapus')),
      );
      // Muat ulang data setelah berhasil menghapus
      await _loadHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Attendance"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            _formattedMonth,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    // ... (kode filter chips tidak berubah)
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip("All"),
          _buildFilterChip("Early Leave"),
          _buildFilterChip("Late In"),
          _buildFilterChip("Absent"),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    // ... (kode filter chip tidak berubah)
    final bool isActive = _activeFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (selected) {
          if (selected) {
            _applyFilter(label);
          }
        },
        selectedColor: primaryColor.withOpacity(0.9),
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.black54,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isActive ? primaryColor : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          "Error: $_errorMessage",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_filteredHistory.isEmpty) {
      return const Center(
        child: Text("Tidak ada data absensi untuk filter ini."),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final item = _filteredHistory[index];
        // BARU: Bungkus _buildHistoryCard dengan Dismissible
        return Dismissible(
          key: Key(item.id.toString()), // Key unik untuk setiap item
          direction:
              DismissDirection.endToStart, // Arah geser dari kanan ke kiri
          background: Container(
            color: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            // BARU: Tampilkan dialog konfirmasi sebelum menghapus
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Konfirmasi Hapus"),
                  content: const Text(
                    "Apakah Anda yakin ingin menghapus data absensi ini?",
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Hapus"),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            // BARU: Panggil fungsi hapus setelah dikonfirmasi
            _deleteAttendanceItem(item.id);
            // Hapus item dari UI secara sementara
            setState(() {
              _allHistory.removeWhere((element) => element.id == item.id);
              _filteredHistory.removeAt(index);
            });
          },
          child: _buildHistoryCard(item),
        );
      },
      separatorBuilder: (context, index) {
        final currentItem = _filteredHistory[index];
        if (currentItem.date.weekday == DateTime.saturday ||
            currentItem.date.weekday == DateTime.sunday) {
          return _buildWeekendSeparator(currentItem.date);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWeekendSeparator(DateTime date) {
    // ... (kode pemisah akhir pekan tidak berubah)
    String message = date.weekday == DateTime.saturday
        ? "Weekend: ${DateFormat('d MMM').format(date)} Sat"
        : "Weekend: ${DateFormat('d MMM').format(date)} Sun";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Attendance item) {
    // ... (kode kartu absensi tidak berubah)
    String workingHours = '--h --m';
    if (item.checkIn != null && item.checkOut != null) {
      try {
        final checkInTime = DateFormat('HH:mm').parse(item.checkIn!);
        final checkOutTime = DateFormat('HH:mm').parse(item.checkOut!);
        final duration = checkOutTime.difference(checkInTime);
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        workingHours =
            "${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m";
      } catch (e) {
        // Biarkan default jika ada error parsing
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Kolom Tanggal
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: _getStatusColor(item.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(item.date),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('E').format(item.date), // E.g., Thu
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Kolom Jam
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeColumn("Clock in", item.checkIn),
                _buildTimeColumn("Clock out", item.checkOut),
                _buildTimeColumn("Working hrs", workingHours, isDuration: true),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status Chip
          _buildStatusChip(item.status),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(
    String label,
    String? time, {
    bool isDuration = false,
  }) {
    // ... (kode kolom waktu tidak berubah)
    return Column(
      children: [
        Icon(
          isDuration ? Icons.timelapse : Icons.access_time,
          color: Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          time ?? '--:--',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    // ... (kode chip status tidak berubah)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(), // Ubah jadi uppercase agar konsisten
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    // ... (kode warna status tidak berubah)
    switch (status.toLowerCase()) {
      case 'masuk':
      case 'present':
        return Colors.green;
      case 'terlambat':
      case 'late in':
        return Colors.orange;
      case 'izin':
      case 'sakit':
      case 'absent':
        return Colors.red;
      case 'early leave':
      case 'leave':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
