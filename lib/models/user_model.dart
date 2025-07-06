class User {
  final int id;
  final String nama;
  final String email;
  final String role;

  User({required this.id, required this.nama, required this.email, required this.role});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nama: map['nama'],
      email: map['email'],
      role: map['role'],
    );
  }
}