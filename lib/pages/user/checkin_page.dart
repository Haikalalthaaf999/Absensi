// lib/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:project3/api/api_service.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:project3/utils/session_manager.dart';

const Color primaryColor = Color(0xFF006769);
const Color accentColor = Color(0xFF40A578);

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
  String? _token;
  Position? _currentPosition;
  String _currentAddress = "Memuat alamat...";
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
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      _token = await _sessionManager.getToken();
      if (_token == null) return;

      final localAttendance = await _sessionManager
          .getTodayAttendanceFromLocal();
      if (localAttendance != null) {
        if (mounted) {
          setState(() {
            _todayAttendance = localAttendance;
          });
        }
      } else {
        final attendanceResult = await ApiService.getTodayAttendance(_token!);
        if (mounted && attendanceResult['data'] != null) {
          _todayAttendance = Attendance.fromJson(attendanceResult['data']);
        } else {
          _todayAttendance = null;
        }
      }

      await _getCurrentLocation();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }

    _currentPosition = await Geolocator.getCurrentPosition();

    List<Placemark> placemarks = await placemarkFromCoordinates(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      _currentAddress =
          "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
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
  }

  void _handleAttendance() {
    if (_todayAttendance?.status == 'izin' ||
        _todayAttendance?.checkOut != null)
      return;

    if (_todayAttendance?.status == 'masuk') {
      _performCheckOut();
    } else {
      _showCheckInOptions();
    }
  }

  void _showCheckInOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Aksi'),
        content: const Text('Silakan pilih status kehadiran Anda hari ini.'),
        actions: [
          TextButton(
            child: const Text('Izin / Sakit'),
            onPressed: () {
              Navigator.pop(context);
              _showIzinDialog();
            },
          ),
          ElevatedButton(
            child: const Text('Hadir (Check In)'),
            onPressed: () {
              Navigator.pop(context);
              _performCheckIn();
            },
          ),
        ],
      ),
    );
  }

  void _showIzinDialog() {
    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajukan Izin / Sakit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
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
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        hintText: 'Cth: Sakit demam',
                        labelText: 'Alasan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (reasonController.text.isNotEmpty) {
                      Navigator.pop(context);
                      _submitIzin(reasonController.text, selectedDate);
                    }
                  },
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitIzin(String reason, DateTime selectedDate) async {
    if (_token == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.submitIzin(
        token: _token!,
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
        reason: reason,
      );
      if (mounted) {
        final now = DateTime.now();
        final isToday =
            selectedDate.year == now.year &&
            selectedDate.month == now.month &&
            selectedDate.day == now.day;

        if (isToday && result['data'] != null) {
          await _sessionManager.saveTodayAttendance(result['data']);
          setState(() {
            _todayAttendance = Attendance.fromJson(result['data']);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Pengajuan izin berhasil!'),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengajukan izin: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI CHECK-IN YANG SUDAH DISEDERHANAKAN ---
  void _performCheckIn() async {
    if (_token == null || _currentPosition == null) return;
    setState(() => _isLoading = true);

    try {
      // Langsung kirim status 'masuk' tanpa logika pengecekan waktu
      final result = await ApiService.checkIn(
        token: _token!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress,
        status: 'masuk', // <-- Status selalu 'masuk'
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Check In Berhasil!')),
        );
        await _loadInitialData(); // Muat ulang data untuk update UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal Check In: $e')));
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _performCheckOut() async {
    if (_token == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data tidak lengkap untuk checkout.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.checkOut(
        token: _token!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress,
      );
      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          await _sessionManager.saveTodayAttendance(result['data']);
          setState(() {
            _todayAttendance = Attendance.fromJson(result['data']);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Berhasil Check Out!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal melakukan check-out'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal Check Out: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

  // Lokasi: lib/screens/map_screen.dart

  Widget _buildMapOverlayButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        // Stack memungkinkan kita menumpuk widget di posisi yang tepat
        child: Stack(
          children: [
            // 1. Jam di TENGAH ATAS
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
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

            // 2. Tombol Lokasi di KANAN ATAS
            Align(
              alignment: Alignment.topRight,
              child: _buildCircleButton(
                icon: Icons.my_location, // Mengganti ikon menjadi lebih sesuai
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
        color: Colors.white,
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
    String statusText;
    String buttonText;
    Color statusColor;
    bool isButtonEnabled = true;

    if (_todayAttendance?.status == 'izin') {
      statusText = 'Izin (${_todayAttendance!.reason})';
      buttonText = 'Anda Sedang Izin';
      statusColor = Colors.orange;
      isButtonEnabled = false;
    } else if (_todayAttendance?.checkOut != null) {
      statusText = 'Sudah Check Out';
      buttonText = 'Absensi Selesai';
      statusColor = Colors.grey;
      isButtonEnabled = false;
    } else if (_todayAttendance?.checkIn != null) {
      statusText = 'Sudah Check In';
      buttonText = 'Check Out';
      statusColor =
          Colors.green; // Selalu hijau karena tidak ada status terlambat
    } else {
      statusText = 'Belum Check In';
      buttonText = 'Pilih Aksi Absen';
      statusColor = Colors.red;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.black26)],
          ),
          child: ListView(
            controller: scrollController,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Absensi Lokasi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading && _currentAddress == "Memuat alamat...")
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("Mencari lokasi..."),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentAddress,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    const Divider(height: 24),
                    Text(
                      'Jarak dari Kantor',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      '${_distanceFromOffice.toStringAsFixed(0)} meter',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Status Hari Ini',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || !isButtonEnabled
                            ? null
                            : _handleAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isButtonEnabled
                              ? accentColor
                              : Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                buttonText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
