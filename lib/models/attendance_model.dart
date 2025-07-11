// lib/models/attendance_model.dart

import 'dart:convert';

class Attendance {
  final int id;
  final int userId;
  final String date; // Tipe data diubah ke String agar aman
  final String? checkIn;
  final String? checkOut;
  final String? checkInLat;
  final String? checkInLng;
  final String? checkInAddress;
  final String? checkOutLat;
  final String? checkOutLng;
  final String? checkOutAddress;
  final String? reason;
  final String status;

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.checkInLat,
    this.checkInLng,
    this.checkInAddress,
    this.checkOutLat,
    this.checkOutLng,
    this.checkOutAddress,
    this.reason,
    required this.status,
  });

 factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json["id"] ?? 0,
      userId: json["user_id"] ?? 0,
      date: json["attendance_date"] ?? '',

      // PERBAIKAN: Mengambil data dari "check_in_time" sesuai respons server
      checkIn: json["check_in_time"],

      // Saya juga menambahkan pengecekan untuk check_out untuk berjaga-jaga
      checkOut: json["check_out_time"] ?? json["check_out"],

      checkInLat: json["check_in_lat"]?.toString(),
      checkInLng: json["check_in_lng"]?.toString(),
      checkInAddress: json["check_in_address"],
      checkOutLat: json["check_out_lat"]?.toString(),
      checkOutLng: json["check_out_lng"]?.toString(),
      checkOutAddress: json["check_out_address"],
      reason: json["alasan_izin"],
      status: json["status"] ?? 'Tidak Diketahui',
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "attendance_date": date,
    "check_in": checkIn,
    "check_out": checkOut,
    "check_in_lat": checkInLat,
    "check_in_lng": checkInLng,
    "check_in_address": checkInAddress,
    "check_out_lat": checkOutLat,
    "check_out_lng": checkOutLng,
    "check_out_address": checkOutAddress,
    "alasan_izin": reason,
    "status": status,
  };
}
