import 'package:flutter/material.dart';
import 'models.dart';

class AppThemes {
  static List<AppThemeData> allThemes = [
    // 1. الثيم الافتراضي (أمواج دردشاتي)
    AppThemeData(
      name: 'dardashati_wave',
      primaryColor: const Color(0xFF7C6BE0),
      gradientColors: [const Color(0xFFF6F3FF), const Color(0xFFEAF8F6)],
      text: const Color(0xFF2A2750),      // حل مشكلة الخطأ في profile_screen
      button: const Color(0xFF7C6BE0),    // حل مشكلة الخطأ في profile_screen
      borderRadius: 30.0,
    ),
    
    // 2. الثيم المودرن الزجاجي
    AppThemeData(
      name: 'soft_glass',
      primaryColor: const Color(0xFF6366F1),
      gradientColors: [const Color(0xFFF8FAFD), const Color(0xFFE2E8F0)],
      text: const Color(0xFF1E293B),
      button: const Color(0xFF6366F1),
      borderRadius: 25.0,
    ),
    
    // 3. الثيم الملكي المذهب
    AppThemeData(
      name: 'royal_gold',
      primaryColor: const Color(0xFFD4AF37),
      gradientColors: [const Color(0xFF1A1A1A), const Color(0xFF2C2C2C)],
      text: const Color(0xFFEFDEC1),
      button: const Color(0xFFD4AF37),
      borderRadius: 35.0,
    ),
    
    // 4. الثيم الغابة الليلية (Dark Mode)
    AppThemeData(
      name: 'night_forest',
      primaryColor: const Color(0xFF2E7D32),
      gradientColors: [const Color(0xFF0D1310), const Color(0xFF1B2420)],
      text: const Color(0xFFE8F5E9),
      button: const Color(0xFF2E7D32),
      borderRadius: 30.0,
    ),
  ];
}
