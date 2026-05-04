import 'package:flutter/material.dart';
import 'models.dart';

class AppThemes {
  static List<AppThemeData> allThemes = [
    // 1. الثيم الافتراضي (أمواج دردشاتي) - Light Mode
    AppThemeData(
      name: 'dardashati_wave',
      label: 'أمواج دردشاتي (الافتراضي)',
      primaryColor: const Color(0xFF7C6BE0),
      gradientColors: [const Color(0xFFF6F3FF), const Color(0xFFEAF8F6)],
      background: const Color(0xFFF6F3FF),
      text: const Color(0xFF2A2750),      
      button: const Color(0xFF7C6BE0),    
      card: Colors.white.withOpacity(0.45),
      accent: const Color(0xFF3FB8B0),   // الفيروزي للتوازن
      menu: Colors.white.withOpacity(0.9),
      buttonText: Colors.white,
      isDark: false,
      borderRadius: 30.0,
    ),
    
    // 2. الثيم المودرن الزجاجي - Light Mode
    AppThemeData(
      name: 'soft_glass',
      label: 'مودرن زجاجي',
      primaryColor: const Color(0xFF6366F1),
      gradientColors: [const Color(0xFFF8FAFD), const Color(0xFFE2E8F0)],
      background: const Color(0xFFF8FAFD),
      text: const Color(0xFF1E293B),
      button: const Color(0xFF6366F1),
      card: Colors.white.withOpacity(0.7),
      accent: const Color(0xFF38BDF8),
      menu: const Color(0xFFF1F5F9).withOpacity(0.9),
      buttonText: Colors.white,
      isDark: false,
      borderRadius: 25.0,
    ),
    
    // 3. الثيم الملكي المذهب - Dark Mode
    AppThemeData(
      name: 'royal_gold',
      label: 'الملكي المذهب',
      primaryColor: const Color(0xFFD4AF37),
      gradientColors: [const Color(0xFF1A1A1A), const Color(0xFF2C2C2C)],
      background: const Color(0xFF1A1A1A),
      text: const Color(0xFFEFDEC1),
      button: const Color(0xFFD4AF37),
      card: const Color(0xFFD4AF25).withOpacity(0.08),
      accent: const Color(0xFFF9F1D2),
      menu: const Color(0xFF2C2C2C),
      buttonText: const Color(0xFF1A1A1A),
      isDark: true,
      borderRadius: 35.0,
    ),
    
    // 4. الثيم الغابة الليلية - Dark Mode
    AppThemeData(
      name: 'night_forest',
      label: 'الغابة الليلية',
      primaryColor: const Color(0xFF2E7D32),
      gradientColors: [const Color(0xFF0D1310), const Color(0xFF1B2420)],
      background: const Color(0xFF0D1310),
      text: const Color(0xFFE8F5E9),
      button: const Color(0xFF2E7D32),
      card: Colors.white.withOpacity(0.04),
      accent: const Color(0xFF66BB6A),
      menu: const Color(0xFF0D1310).withOpacity(0.95),
      buttonText: Colors.white,
      isDark: true,
      borderRadius: 30.0,
    ),
  ];
}
