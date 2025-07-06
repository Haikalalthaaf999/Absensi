import 'package:flutter/material.dart';

// Palet Warna
const Color primaryColor = Color(0xFF6A1B9A); // Ungu Tua
const Color secondaryColor = Color(0xFFF3E5F5); // Ungu Muda
const Color backgroundColor = Color(0xFFF5F5F5); // Abu-abu sangat muda
const Color textColor = Color(0xFF333333); // Abu-abu tua untuk teks

// Style untuk Tombol Utama
final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryColor,
  foregroundColor: Colors.white,
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.symmetric(vertical: 16),
);

// Style untuk Input Field
InputDecoration customInputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: primaryColor),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
  );
}