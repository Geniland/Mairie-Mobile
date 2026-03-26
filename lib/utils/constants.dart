import 'package:flutter/material.dart';

class AppConstants {
  // Base URL for the API
  static const String baseUrl = 'https://159a-102-64-161-253.ngrok-free.app/api'; // Replace with actual server URL if different

  // Colors based on the web design
  static const Color primaryColor = Color(0xFF0EA5E9);
  static const Color secondaryColor = Color(0xFF1E293B);
  static const Color backgroundColor = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF10B981);

  // Gradient for login
  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E293B),
      Color(0xFF0F172A),
    ],
  );
}
