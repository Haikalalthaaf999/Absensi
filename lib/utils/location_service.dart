import 'package:geolocator/geolocator.dart';

class LocationService {
  // --- GANTI KOORDINAT INI DENGAN KOORDINAT KANTOR ANDA ---
  static const double _officeLatitude = -6.1753924; // Contoh: Latitude Monas
  static const double _officeLongitude = 106.8271528; // Contoh: Longitude Monas
  // ---------------------------------------------------------

  /// Meminta izin dan mendapatkan posisi GPS pengguna saat ini.
  /// Melemparkan Exception jika izin ditolak atau layanan lokasi mati.
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan lokasi di perangkat aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi mati. Silakan aktifkan GPS Anda.');
    }

    // 2. Cek status izin lokasi saat ini
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Jika ditolak, minta izin kepada pengguna
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Izin lokasi ditolak. Aplikasi tidak dapat melanjutkan.',
        );
      }
    }

    // 3. Jika izin ditolak selamanya, aplikasi tidak bisa meminta lagi
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak secara permanen. Anda harus mengaktifkannya melalui pengaturan aplikasi.',
      );
    }

    // 4. Jika semua izin sudah didapat, ambil lokasi saat ini
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Menghitung jarak antara posisi pengguna dengan kantor dalam satuan meter.
  static double calculateDistance(double userLat, double userLng) {
    return Geolocator.distanceBetween(
      _officeLatitude,
      _officeLongitude,
      userLat,
      userLng,
    );
  }
}
