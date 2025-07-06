import 'package:project3/common/theme.dart';
import 'package:project3/helper/database_helper.dart';
import 'package:project3/models/attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  final int userId;
  const HistoryPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Absensi", style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: textColor),
      ),
      body: FutureBuilder<List<Attendance>>(
        future: DatabaseHelper().getAttendanceHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada riwayat."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final attendance = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.yMMMMEEEEd('id_ID').format(attendance.jamMasuk!),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTimeInfo("Clock In", attendance.jamMasuk),
                          _buildTimeInfo("Clock Out", attendance.jamPulang),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeInfo(String title, DateTime? time) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          time != null ? DateFormat.Hms('id_ID').format(time) : '--:--:--',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
        ),
      ],
    );
  }
}