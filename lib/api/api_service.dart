// lib/api/api_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project3/models/batch_model.dart';
import 'package:project3/models/training_model.dart';

class ApiService {
  // BASE URL yang benar (tanpa /api di akhir)
  // Ganti _baseUrl menjadi baseUrl (hapus underscore)
  // Ini akan membuatnya bisa diakses publik dari luar file
  static const String baseUrl =
      'https://appabsensi.mobileprojp.com'; // [PERBAIKAN UTAMA DI SINI]

  // Helper untuk membuat headers, digunakan di semua fungsi
  static Map<String, String> _getHeaders({String? token}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Endpoint: /api/profile (Untuk mengambil data user terbaru)
  static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      // Menggunakan ApiService.baseUrl secara konsisten
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/profile',
        ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Mengembalikan pesan error dari server jika ada
        final errorData = json.decode(response.body);
        return {'message': errorData['message'] ?? 'Gagal memuat profil'};
      }
    } catch (e) {
      return {'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required Map<String, String> data,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/profile'),
      headers: _getHeaders(token: token),
      body: jsonEncode(data),
    );
    // Langsung decode dan kembalikan respons dari server
    return jsonDecode(response.body);
  }

  /// Endpoint: /api/profile/photo (Untuk update foto profil)
  static Future<Map<String, dynamic>> updateProfilePhoto({
    required String token,
    required String base64Photo,
  }) async {
    final body = {'profile_photo': 'data:image/png;base64,$base64Photo'};
    final response = await http.put(
      Uri.parse(
        '$baseUrl/api/profile/photo',
      ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
      headers: _getHeaders(token: token),
      body: jsonEncode(body),
    );
    return json.decode(response.body);
  }

  /// Endpoint: /api/login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
    String deviceToken,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/login',
      ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
      headers: _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_token': deviceToken, // Tambahkan ini ke body jika dibutuhkan
      }),
    );
    return jsonDecode(response.body);
  }

  /// Endpoint: /api/register (Diperbarui dengan parameter lengkap)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String jenisKelamin,
    required int trainingId,
    required int batchId, // Dibuat wajib kembali sesuai API
    String? profilePhoto, // Opsional
  }) async {
    Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'password': password,
      'jenis_kelamin': jenisKelamin,
      'training_id': trainingId,
      'batch_id': batchId,
    };
    if (profilePhoto != null) {
      body['profile_photo'] = profilePhoto;
    }

    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/register',
      ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
    return json.decode(response.body);
  }

  // --- FUNGSI GETTRAININGS DIPERBARUI ---
  static Future<ListJurusan> getTrainings() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/trainings',
      ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Langsung parse JSON menjadi objek ListJurusan
      return listJurusanFromJson(response.body);
    } else {
      throw Exception('Gagal memuat data training');
    }
  }

  /// Endpoint: /api/batches (Publik, sesuai pembaruan)
  static Future<BatchResponse> getBatches() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/batches',
      ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      // Langsung parse JSON menjadi objek BatchResponse
      return batchResponseFromJson(response.body);
    } else {
      throw Exception('Gagal memuat data batch');
    }
  }

  /// Endpoint: /api/izin (Baru)
  static Future<Map<String, dynamic>> submitIzin({
    required String token,
    required String date,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/izin',
      ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
      headers: _getHeaders(token: token),
      body: jsonEncode({'date': date, 'alasan_izin': reason}),
    );
    return json.decode(response.body);
  }

  /// Endpoint: /api/absen/check-in
   static Future<Map<String, dynamic>> checkIn({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final now = DateTime.now();
      final String formattedDate = DateFormat('yyyy-MM-dd').format(now);

      // ==========================================================
      // PERBAIKAN DI SINI: Hapus ':ss' dari format waktu
      final String formattedTime = DateFormat('HH:mm').format(now);
      // ==========================================================

      Map<String, dynamic> body = {
        'check_in_lat': latitude.toString(),
        'check_in_lng': longitude.toString(),
        'check_in_address': address,
        'status': 'masuk',
        'attendance_date': formattedDate,
        'check_in': formattedTime,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/absen/check-in'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );

      // Anda bisa menghapus print ini jika sudah berhasil
      print('SERVER RESPONSE STATUS CODE: ${response.statusCode}');
      print('SERVER RESPONSE BODY: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server memberikan respons kosong',
        };
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Endpoint: /api/absen/check-out
 static Future<Map<String, dynamic>> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    // BARU: Siapkan data waktu saat ini untuk check-out
    final String formattedTime = DateFormat('HH:mm').format(DateTime.now());

    // MODIFIKASI: Tambahkan field 'check_out' ke dalam body
    final response = await http.post(
      Uri.parse('$baseUrl/api/absen/check-out'),
      headers: _getHeaders(token: token),
      body: jsonEncode({
        'check_out_lat': latitude.toString(),
        'check_out_lng': longitude.toString(),
        'check_out_address': address,
        'check_out': formattedTime, // Data jam yang diwajibkan server
      }),
    );
    return jsonDecode(response.body);
  }

  /// Endpoint: /api/absen/today
  static Future<Map<String, dynamic>> getTodayAttendance(String token) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/absen/today',
      ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
      headers: _getHeaders(token: token),
    );
    return jsonDecode(response.body);
  }

  /// Endpoint: /api/absen/stats (Untuk statistik di HomeScreen)
  static Future<Map<String, dynamic>> getAbsenStats(String token) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/absen/stats',
      ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
      headers: _getHeaders(token: token),
    );
    return jsonDecode(response.body);
  }

  /// Endpoint: /api/absen/history
  static Future<Map<String, dynamic>> getHistory(
    String token, {
    String? startDate,
    String? endDate,
  }) async {
    var uri = Uri.parse(
      '$baseUrl/api/absen/history',
    ); // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
    if (startDate != null && endDate != null) {
      uri = uri.replace(queryParameters: {'start': startDate, 'end': endDate});
    }
    final response = await http.get(uri, headers: _getHeaders(token: token));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteAttendance({
    required String token,
    required int id,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/api/absen/$id',
      ), // [PERBAIKAN: Gunakan 'baseUrl' tanpa underscore]
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal menghapus data absen');
    }
  }
}
