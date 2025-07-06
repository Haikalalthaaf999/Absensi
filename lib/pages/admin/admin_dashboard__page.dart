import 'package:project3/common/theme.dart';
import 'package:project3/helper/database_helper.dart';
import 'package:project3/pages/auth/login_page.dart';
import 'package:project3/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  void _logout() async {
    await SessionService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (c) => LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: textColor))],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getAdminAttendanceHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada data absensi."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              final jamMasuk = item['jamMasuk'] != null ? DateTime.parse(item['jamMasuk']) : null;
              final jamPulang = item['jamPulang'] != null ? DateTime.parse(item['jamPulang']) : null;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(backgroundColor: primaryColor, child: Text(item['nama'][0], style: const TextStyle(color: Colors.white))),
                  title: Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Masuk: ${jamMasuk != null ? DateFormat('dd MMM, HH:mm').format(jamMasuk) : '-'}\n'
                    'Pulang: ${jamPulang != null ? DateFormat('dd MMM, HH:mm').format(jamPulang) : '-'}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}