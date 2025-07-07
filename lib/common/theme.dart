import 'package:flutter/material.dart';

// Palet Warna
const Color primaryColor = Color(0xFF0D47A1); // Biru Tua
const Color secondaryColor = Color(0xFFE3F2FD); // Biru Sangat Muda
const Color backgroundColor = Colors.white; // Latar belakang putih
const Color textColor = Color(0xFF333333);
const Color accentColor = Color(0xFF4CAF50); // Hijau untuk status "On Time"
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