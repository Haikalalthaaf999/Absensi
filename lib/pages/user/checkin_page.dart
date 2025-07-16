import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:project3/api/api_service.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/utils/session_manager.dart';
import 'package:shimmer/shimmer.dart';

const Color primaryColor = Color(0xFF006769);
const Color accentColor = Color(0xFF40A578);
const Color backgroundColor = Color(0xffF7E9D7);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  final SessionManager _sessionManager = SessionManager();

  bool _isLoading = true;
  bool _isProcessingAttendance = false;
  String? _token;
  Position? _currentPosition;
  String _currentAddress = "";
  Attendance? _todayAttendance;

  final LatLng _officePosition = const LatLng(-6.2109, 106.8129);
  double _distanceFromOffice = 0.0;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      _token = await _sessionManager.getToken();
      if (_token == null) return;

      final attendanceResult = await ApiService.getTodayAttendance(_token!);
      if (mounted && attendanceResult['data'] != null) {
        _todayAttendance = Attendance.fromJson(attendanceResult['data']);
        await _sessionManager.saveTodayAttendance(attendanceResult['data']);
      } else {
        _todayAttendance = null;
        await _sessionManager.clearTodayAttendance();
      }

      await _getCurrentLocation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak.')),
            );
          }
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      if (mounted && placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
        });
      }

      _distanceFromOffice = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _officePosition.latitude,
        _officePosition.longitude,
      );

      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              infoWindow: const InfoWindow(title: 'Lokasi Anda'),
            ),
          );
        });

        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 16,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      }
    }
  }

  void _handleAttendance() {
    if (_todayAttendance?.status == 'izin') {
      return;
    }

    if (_todayAttendance?.checkOut != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Anda sudah melakukan checkout. Absensi hari ini telah selesai.',
          ),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    if (_todayAttendance?.status == 'masuk') {
      _performCheckOut();
    } else {
      _showCheckInOptions();
    }
  }

  void _performCheckIn() async {
    if (_token == null || _currentPosition == null) return;
    setState(() => _isProcessingAttendance = true);

    try {
      final result = await ApiService.checkIn(
        token: _token!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress,
        status: 'masuk',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Check In Berhasil!'),
            backgroundColor: accentColor,
          ),
        );
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal Check In: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessingAttendance = false);
    }
  }

  void _performCheckOut() async {
    if (_token == null || _currentPosition == null) return;
    setState(() => _isProcessingAttendance = true);

    try {
      final result = await ApiService.checkOut(
        token: _token!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Berhasil Check Out!'),
            backgroundColor: accentColor,
          ),
        );
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal Check Out: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessingAttendance = false);
    }
  }

  void _submitIzin(String reason, DateTime selectedDate) async {
    if (_token == null) return;
    setState(() => _isProcessingAttendance = true);
    try {
      final result = await ApiService.submitIzin(
        token: _token!,
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Pengajuan izin berhasil!'),
            backgroundColor: accentColor,
          ),
        );
        final now = DateTime.now();
        final isToday =
            selectedDate.year == now.year &&
            selectedDate.month == now.month &&
            selectedDate.day == now.day;
        if (isToday) {
          await _loadInitialData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengajukan izin: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessingAttendance = false);
    }
  }

  void _showCheckInOptions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.touch_app_outlined,
                    color: primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Aksi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan pilih status kehadiran Anda hari ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.fingerprint, size: 20),
                  label: const Text('Hadir (Check In)'),
                  onPressed: () {
                    Navigator.pop(context);
                    _performCheckIn();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_busy_outlined, size: 20),
                  label: const Text('Ajukan Izin / Sakit'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showIzinDialog();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIzinDialog() {
    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_busy_outlined,
                            color: primaryColor,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Ajukan Izin / Sakit',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Pilih Tanggal Izin:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                          );
                          if (picked != null && picked != selectedDate) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat(
                                  'EEEE, d MMMM yyyy',
                                ).format(selectedDate),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Alasan:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          hintText: 'Cth: Sakit demam',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (reasonController.text.isNotEmpty) {
                                Navigator.pop(context);
                                _submitIzin(
                                  reasonController.text,
                                  selectedDate,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Kirim'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Build body
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _officePosition,
              zoom: 14,
            ),
            zoomControlsEnabled: false,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
          ),
          _buildMapOverlayButtons(),
          _buildAttendancePanel(),
        ],
      ),
    );
  }

  Widget _buildMapOverlayButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: _buildCircleButton(
                icon: Icons.my_location,
                onPressed: _getCurrentLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: primaryColor),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildAttendancePanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.black26)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Absensi Lokasi',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _showIzinDialog,
                    icon: const Icon(Icons.note_add_outlined, size: 20),
                    label: const Text('Ajukan Izin'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading) _buildShimmerEffect() else _buildAttendanceInfo(),
              const SizedBox(height: 20),
            _buildCopyright(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceInfo() {
    String statusText;
    String buttonText;
    Color statusColor;
    bool isButtonEnabled = true;

    if (_todayAttendance?.status == 'izin') {
      statusText = 'Izin (${_todayAttendance!.reason})';
      buttonText = 'Anda Sedang Izin';
      statusColor = Colors.orange.shade700;
      isButtonEnabled = false;
    } else if (_todayAttendance?.checkOut != null) {
      statusText = 'Selesai';
      buttonText = 'Absensi Selesai';
      statusColor = Colors.grey.shade600;
      isButtonEnabled = false;
    } else if (_todayAttendance?.checkIn != null) {
      statusText = 'Sudah Check In';
      buttonText = 'Check Out Sekarang';
      statusColor = Colors.green.shade600;
    } else {
      statusText = 'Belum Check In';
      buttonText = 'Pilih Aksi Absen';
      statusColor = Colors.red.shade600;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoTile(
          icon: Icons.location_on_outlined,
          label: 'Lokasi Anda Saat Ini',
          value: _currentAddress.isEmpty ? 'Tidak terdeteksi' : _currentAddress,
        ),
        _buildInfoTile(
          icon: Icons.social_distance_outlined,
          label: 'Jarak dari Kantor',
          value: '${_distanceFromOffice.toStringAsFixed(0)} meter',
          valueColor: accentColor,
        ),
        _buildInfoTile(
          icon: Icons.today_outlined,
          label: 'Status Hari Ini',
          value: statusText,
          valueColor: statusColor,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            text: buttonText,
            isEnabled: isButtonEnabled,
            onPressed: _handleAttendance,
          ),
        ),
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
          style: const TextStyle(fontSize: 12, color: Color(0xff046865)),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: primaryColor, size: 28),
      title: Text(
        label,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: valueColor ?? Colors.black87,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isProcessingAttendance || !isEnabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        disabledBackgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isEnabled ? 2 : 0,
      ),
      child: _isProcessingAttendance
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Memproses...',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[400]!,
      highlightColor: Colors.grey[200]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerTile(),
          _buildShimmerTile(),
          _buildShimmerTile(),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
      title: Container(width: 100, height: 12, color: Colors.white),
      subtitle: Container(
        width: 200,
        height: 16,
        margin: const EdgeInsets.only(top: 4),
        color: Colors.white,
      ),
    );
  }
}
