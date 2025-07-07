// lib/models/attendance_model.dart

class Attendance {
  final int id;
  final int userId;
  final String? checkIn;
  final String? checkOut;
  final String? checkInLocation; // Tambahan
  final String? checkOutLocation; // Tambahan
  final String? checkInAddress;
  final String? checkOutAddress;
  final String status;
  final String? alasanIzin;

  Attendance({
    required this.id,
    required this.userId,
    this.checkIn,
    this.checkOut,
    this.checkInLocation, // Tambahan
    this.checkOutLocation, // Tambahan
    this.checkInAddress,
    this.checkOutAddress,
    required this.status,
    this.alasanIzin,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      userId: json['user_id'],
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      checkInLocation: json['check_in_location'], // Tambahan
      checkOutLocation: json['check_out_location'], // Tambahan
      checkInAddress: json['check_in_address'],
      checkOutAddress: json['check_out_address'],
      status: json['status'],
      alasanIzin: json['alasan_izin'],
    );
  }
}
