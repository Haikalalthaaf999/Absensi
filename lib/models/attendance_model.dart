class Attendance {
  final int id;
  final int userId;
  final DateTime? jamMasuk;
  final DateTime? jamPulang;
  final String? lokasiMasuk;
  final String? lokasiPulang;

  Attendance({
    required this.id,
    required this.userId,
    this.jamMasuk,
    this.jamPulang,
    this.lokasiMasuk,
    this.lokasiPulang,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      userId: map['userId'],
      jamMasuk: map['jamMasuk'] != null ? DateTime.parse(map['jamMasuk']) : null,
      jamPulang: map['jamPulang'] != null ? DateTime.parse(map['jamPulang']) : null,
      lokasiMasuk: map['lokasiMasuk'],
      lokasiPulang: map['lokasiPulang'],
    );
  }
}