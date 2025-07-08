// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // BASE URL yang benar (tanpa /api di akhir)
  static const String _baseUrl = 'https://appabsensi.mobileprojp.com';

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

  /// Endpoint: /api/login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/login'),
      headers: _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
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
      Uri.parse('$_baseUrl/api/register'),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
    return json.decode(response.body);
  }

  /// Endpoint: /api/trainings (Publik)
  static Future<Map<String, dynamic>> getTrainings() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/trainings'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data training');
    }
  }

  /// Endpoint: /api/batches (Publik, sesuai pembaruan)
  static Future<Map<String, dynamic>> getBatches() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/batches'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
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
      Uri.parse('$_baseUrl/api/izin'),
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
    Map<String, dynamic> body = {
      'check_in_lat': latitude.toString(),
      'check_in_lng': longitude.toString(),
      'check_in_address': address,
      'status': 'masuk', // Status selalu 'masuk' untuk endpoint ini
    };
    final response = await http.post(
      Uri.parse('$_baseUrl/api/absen/check-in'),
      headers: _getHeaders(token: token),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  /// Endpoint: /api/absen/check-out
  static Future<Map<String, dynamic>> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/absen/check-out'),
      headers: _getHeaders(token: token),
      body: jsonEncode({
        'check_out_lat': latitude.toString(),
        'check_out_lng': longitude.toString(),
        'check_out_address': address,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Endpoint: /api/absen/today
  static Future<Map<String, dynamic>> getTodayAttendance(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/absen/today'),
      headers: _getHeaders(token: token),
    );
    return jsonDecode(response.body);
  }

  /// Endpoint: /api/absen/stats (Untuk statistik di HomeScreen)
  static Future<Map<String, dynamic>> getAbsenStats(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/absen/stats'),
      headers: _getHeaders(token: token),
    );
    return jsonDecode(response.body);
  }

  /// Endpoint: /api/absen/history
  static Future<Map<String, dynamic>> getHistory(String token, {String? startDate, String? endDate}) async {
    var uri = Uri.parse('$_baseUrl/api/absen/history');
    if (startDate != null && endDate != null) {
      uri = uri.replace(queryParameters: {'start': startDate, 'end': endDate});
    }
    final response = await http.get(uri, headers: _getHeaders(token: token));
    return jsonDecode(response.body);
  }
}