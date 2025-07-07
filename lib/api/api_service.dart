// lib/api/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti dengan base URL dari Postman Anda
  static const String _baseUrl = 'https://appabsensi.mobileprojp.com/api';

  // Helper untuk membuat headers
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

  // Endpoint: /login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // Endpoint: /register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int trainingId,
    // batchId dihapus dari sini
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'training_id': trainingId,
        // 'batch_id': batchId, <-- Baris ini dihapus
      }),
    );
    return json.decode(response.body);
  }
  // Endpoint: /absen/check-in
  static Future<Map<String, dynamic>> checkIn({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
    required String status, // 'masuk' atau 'izin'
    String? reason, // 'alasan_izin' jika status adalah 'izin'
  }) async {
    Map<String, dynamic> body = {
      'check_in_lat': latitude.toString(),
      'check_in_lng': longitude.toString(),
      'check_in_address': address,
      'status': status,
    };

    if (status == 'izin' && reason != null) {
      body['alasan_izin'] = reason;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/absen/check-in'),
      headers: _getHeaders(token: token),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  // Endpoint: /absen/check-out
  static Future<Map<String, dynamic>> checkOut({
    required String token,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/absen/check-out'),
      headers: _getHeaders(token: token),
      body: jsonEncode({
        'check_out_lat': latitude.toString(),
        'check_out_lng': longitude.toString(),
        'check_out_address': address,
      }),
    );
    return jsonDecode(response.body);
  }

  // Endpoint: /absen/today
  static Future<Map<String, dynamic>> getTodayAttendance(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/absen/today'),
      headers: _getHeaders(token: token),
    );
    return jsonDecode(response.body);
  }

  // Endpoint: /absen/history
  static Future<Map<String, dynamic>> getHistory(
    String token, {
    String? startDate,
    String? endDate,
  }) async {
    var uri = Uri.parse('$_baseUrl/absen/history');
    if (startDate != null && endDate != null) {
      uri = uri.replace(queryParameters: {'start': startDate, 'end': endDate});
    }

    final response = await http.get(uri, headers: _getHeaders(token: token));
    return jsonDecode(response.body);
  }
  // Endpoint: /trainings (Untuk dropdown di halaman register)
  static Future<Map<String, dynamic>> getTrainings() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/trainings'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data training');
    }
  }

  // FUNGSI BARU: Mengambil daftar semua batch
  static Future<Map<String, dynamic>> getBatches() async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/batches',
      ), // Pastikan endpoint ini ada di API Anda
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data batch');
    }
  }
}
