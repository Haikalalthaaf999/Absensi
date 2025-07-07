// lib/models/training_model.dart

class Training {
  final int id;
  final String title;

  Training({required this.id, required this.title});

  // Factory constructor untuk membuat Training dari JSON
  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(id: json['id'], title: json['title']);
  }
}
