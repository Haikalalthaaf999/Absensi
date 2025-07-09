// lib/models/attendance_model.dart

import 'dart:convert';
import 'package:intl/intl.dart';

class Attendance {
  final int id;
  final int userId;
  final DateTime date;
  final String? checkIn;
  final String? checkOut;

  // DIUBAH: Tipe data diubah dari String? menjadi double?
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;

  final String? checkInAddress;
  final String? checkOutAddress;
  final String status;
  final String? reason;

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.checkInAddress,
    this.checkOutAddress,
    required this.status,
    this.reason,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    String? formatTime(String? dateTimeString) {
      if (dateTimeString == null) return null;
      try {
        return DateFormat('HH:mm').format(DateTime.parse(dateTimeString));
      } catch (e) {
        return '--:--';
      }
    }

    // DIUBAH: Fungsi parsing baru yang aman untuk double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    return Attendance(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      date: DateTime.parse(
        json['check_in'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      checkIn: formatTime(json["check_in"]),
      checkOut: formatTime(json["check_out"]),
      status: json["status"] ?? 'Tidak Diketahui',
      reason: json["alasan_izin"],

      // DIUBAH: Menggunakan fungsi parseDouble yang baru
      checkInLat: parseDouble(json["check_in_lat"]),
      checkInLng: parseDouble(json["check_in_lng"]),
      checkOutLat: parseDouble(json["check_out_lat"]),
      checkOutLng: parseDouble(json["check_out_lng"]),

      checkInAddress: json["check_in_address"],
      checkOutAddress: json["check_out_address"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "date": date.toIso8601String(),
    "check_in": checkIn,
    "check_out": checkOut,
    "check_in_lat": checkInLat,
    "check_in_lng": checkInLng,
    "check_out_lat": checkOutLat,
    "check_out_lng": checkOutLng,
    "check_in_address": checkInAddress,
    "check_out_address": checkOutAddress,
    "status": status,
    "alasan_izin": reason,
  };
}
