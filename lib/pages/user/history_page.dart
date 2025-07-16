import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/utils/session_manager.dart';

// --- Palet Warna Baru yang Lebih Segar ---
const Color primaryColor = Color(0xFF006769);
const Color accentColor = Color(0xFF40A578);
const Color pageBackgroundColor = Color(0xffF7E9D7);
const Color textColor = Color(0xFF333333);
const Color presentColor = Color(0xFF2E7D32);
const Color absentColor = Color(0xFFD32F2F);
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

  // Fungsi logika (tidak ada perubahan)
  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _filteredHistory = _allHistory.where((item) {
        String status = item.status.toLowerCase();
        if (filter == 'All') return true;
        if (filter == 'Present') {
          return ['masuk', 'present', 'leave'].contains(status);
        }
        if (filter == 'Late In') {
          return ['terlambat', 'late in'].contains(status);
        }
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

  // --- Fungsi untuk menampilkan date picker ---
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryColor,
            colorScheme: const ColorScheme.light(primary: primaryColor),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null &&
        (picked.month != _selectedMonth.month ||
            picked.year != _selectedMonth.year)) {
      setState(() {
        _selectedMonth = picked;
        _activeFilter = 'All';
      });
      _loadHistory();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildMonthSelectorCard(), // Card pemilih bulan
          _buildFilterTabs(), // Tabs filter
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : _errorMessage != null
                ? Center(child: Text("Error: $_errorMessage"))
                : _buildGroupedHistoryList(),
          ),
        _buildCopyright(),
        ],
      ),
    );
  }

  // --- PEMILIH BULAN DENGAN GAYA CARD ---
  Widget _buildMonthSelectorCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: textColor, size: 28),
              onPressed: () => _changeMonth(-1),
            ),
            GestureDetector(
              onTap: () => _selectMonth(context),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formattedMonth,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: textColor, size: 28),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
      ),
    );
  }

  // --- FILTER DENGAN GAYA TABS MODERN ---
  Widget _buildFilterTabs() {
    final filters = ["All", "Present"];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: filters
            .map((label) => Expanded(child: _buildFilterTab(label)))
            .toList(),
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final bool isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : textColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          '© ${DateTime.now().year} Sentinel. All Rights Reserved.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xff046865)),
        ),
      ),
    );
  }
  Widget _buildGroupedHistoryList() {
    if (_filteredHistory.isEmpty) {
      return const Center(
        child: Text("Tidak ada data riwayat untuk bulan ini."),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 55,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
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
                      color: textColor,
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
                        // _buildTimeDetail(
                        //   Icons.schedule,
                        //   workingHours,
                        //   "Durasi",
                        // ),
                      ],
                    ),
            ),
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
            color: textColor,
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
        statusText = 'Hadir';
        break;
      case 'terlambat':
      case 'late in':
        chipColor = lateColor;
        statusText = 'Telat';
        break;
      default:
        chipColor = absentColor;
        statusText = 'Absen';
        break;
    }
    return Container(
      width: 55,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          statusText,
          style: TextStyle(
            color: chipColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
